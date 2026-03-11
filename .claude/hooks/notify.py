#!/usr/bin/env python3
"""Claude Code notification hook using OSC escape sequences and Bark push."""

import argparse
import json
import logging
import os
import subprocess
import sys
import urllib.request
import urllib.parse

LOG_DIR = os.path.join(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")), "bark-notify")
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    filename=os.path.join(LOG_DIR, "notify.log"),
    format="%(asctime)s %(levelname)s %(message)s",
    level=logging.INFO,
)

# Configuration per notification type
NOTIFICATION_CONFIG = {
    "stop": {
        "message": "完了",
        "sound": "Glass",
    },
    "permission_prompt": {
        "message": "許可が必要",
        "sound": "Basso",
    },
    "elicitation_dialog": {
        "message": "入力待ち",
        "sound": "Ping",
    },
}

DEFAULT_CONFIG = {
    "message": "通知",
    "sound": "Pop",
}

BARK_CONTAINER_NAME = "bark-server"
BARK_PORT = "8090"
BARK_ICON_URL = "https://raw.githubusercontent.com/bigdra50/dotfiles/master/icon.png"
MAX_BODY_LENGTH = 200

RELAY_SERVER_URL = os.environ.get("RELAY_SERVER_URL", "http://localhost:3000")


def ensure_bark_server() -> bool:
    """Start bark-server Docker container if not running. Returns True if available."""
    try:
        result = subprocess.run(
            ["docker", "inspect", "-f", "{{.State.Running}}", BARK_CONTAINER_NAME],
            capture_output=True, text=True, timeout=5,
        )
        if result.stdout.strip() == "true":
            return True
        subprocess.run(
            ["docker", "start", BARK_CONTAINER_NAME],
            capture_output=True, timeout=10,
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False
    except Exception:
        return False


MIN_SUBSTANTIAL_LENGTH = 80


def extract_assistant_text(entry: dict) -> str:
    """Extract text content from an assistant transcript entry."""
    message = entry.get("message", {})
    content = message.get("content", [])
    if isinstance(content, str):
        return content
    texts = []
    for block in content:
        if isinstance(block, dict) and block.get("type") == "text":
            text = block.get("text", "")
            if text and text != "(no content)":
                texts.append(text)
    return "\n".join(texts)


def get_last_assistant_text(transcript_path: str) -> str:
    """Extract last substantial assistant text from transcript JSONL."""
    try:
        with open(transcript_path, "r") as f:
            lines = f.readlines()
        fallback = ""
        for line in reversed(lines):
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("type") != "assistant":
                continue
            text = extract_assistant_text(entry)
            if not text:
                continue
            if not fallback:
                fallback = text
            if len(text) >= MIN_SUBSTANTIAL_LENGTH:
                return text
        return fallback
    except Exception:
        return ""


def truncate(text: str, max_length: int = MAX_BODY_LENGTH) -> str:
    """Truncate text to max_length."""
    text = text.replace("\n", " ").strip()
    if len(text) <= max_length:
        return text
    return text[:max_length] + "…"


def summarize(text: str) -> str:
    """Extract first meaningful sentence from text."""
    if not text.strip():
        return ""
    # Strip markdown formatting
    import re
    clean = re.sub(r'```[\s\S]*?```', '', text)  # code blocks
    clean = re.sub(r'`[^`]+`', '', clean)          # inline code
    clean = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', clean)  # links
    clean = re.sub(r'[*_#>|~\-]+', '', clean)      # markdown symbols
    clean = re.sub(r'\s+', ' ', clean).strip()

    # Extract first sentence
    for sep in ['。', '．', '. ']:
        idx = clean.find(sep)
        if 0 < idx <= 100:
            return clean[:idx + len(sep)]

    return truncate(clean, 100)


def send_bark_notification(title: str, body: str) -> None:
    """Send push notification via Bark server."""
    bark_key = os.environ.get("BARK_KEY")
    if not bark_key:
        return

    if not ensure_bark_server():
        return

    try:
        hostname = subprocess.run(
            ["scutil", "--get", "LocalHostName"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
    except Exception:
        hostname = ""
    if not hostname:
        import socket
        hostname = socket.gethostname().split(".")[0]

    base_url = f"http://{hostname}.local:{BARK_PORT}"
    bark_title = urllib.parse.quote(f"{hostname}: {title}", safe="")
    encoded_body = urllib.parse.quote(body, safe="") if body else ""
    params = f"?icon={urllib.parse.quote(BARK_ICON_URL, safe='')}"

    # Truncate body to avoid HTTP 431
    if body and len(body) > 100:
        body = body[:100] + "…"
    encoded_body = urllib.parse.quote(body, safe="") if body else ""

    if encoded_body:
        url = f"{base_url}/{bark_key}/{bark_title}/{encoded_body}{params}"
    else:
        url = f"{base_url}/{bark_key}/{bark_title}{params}"

    logging.debug("bark url=%s", url)
    try:
        resp = urllib.request.urlopen(url, timeout=5)
        logging.info("bark sent status=%s", resp.status)
    except Exception as e:
        logging.error("bark send failed: %s", e)


def send_relay_notification(notification_type: str, title: str, body: str) -> None:
    """Send notification to WebSocket relay server for G2 glass display."""
    payload = json.dumps({
        "type": notification_type,
        "title": title,
        "message": body if body else title,
    }).encode()

    req = urllib.request.Request(
        f"{RELAY_SERVER_URL}/api/notify",
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    try:
        resp = urllib.request.urlopen(req, timeout=3)
        logging.info("relay sent status=%s", resp.status)
    except Exception as e:
        logging.debug("relay send skipped: %s", e)


def send_notification(notification_type: str, hook_input: dict) -> None:
    """Send notification using osascript (macOS built-in) and Bark push."""
    config = NOTIFICATION_CONFIG.get(notification_type, DEFAULT_CONFIG)
    message = config["message"]

    # Build body from transcript first (used by both osascript and Bark)
    body = ""
    raw_text = ""
    transcript_path = hook_input.get("transcript_path", "")
    if transcript_path:
        transcript_path = transcript_path.replace("~", os.path.expanduser("~"))
        raw_text = get_last_assistant_text(transcript_path)
        body = summarize(raw_text)

    # macOS notification via osascript
    osc_body = body if body else message
    osc_script = f'display notification "{osc_body}" with title "{message}"'
    subprocess.run(["osascript", "-e", osc_script], check=False)

    # Play sound
    subprocess.Popen(
        ["afplay", f"/System/Library/Sounds/{config['sound']}.aiff"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    logging.info("type=%s title=%s body=%s raw=%s", notification_type, message, body, raw_text[:200])
    send_bark_notification(message, body)
    send_relay_notification(notification_type, message, body)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--type",
        choices=["stop", "permission_prompt", "elicitation_dialog"],
        required=True,
    )
    args = parser.parse_args()

    hook_input = {}
    if not sys.stdin.isatty():
        try:
            hook_input = json.loads(sys.stdin.read())
        except (json.JSONDecodeError, ValueError):
            pass

    # Use notification_type from stdin JSON if available (more accurate than CLI arg)
    notification_type = hook_input.get("notification_type", args.type)
    send_notification(notification_type, hook_input)


if __name__ == "__main__":
    if sys.platform == "darwin":
        main()
