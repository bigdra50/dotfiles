#!/usr/bin/env python3
"""Claude Code notification hook (cross-platform).

Desktop notification:
  macOS:  terminal-notifier (primary) -> osascript (fallback)
  Linux:  notify-send
  Others: log-only (graceful skip)
Also pushes to a local relay (G2 glasses) when enabled.

Behaviour is tunable via env vars:
  CLAUDE_NOTIFY_SUPPRESS_WHEN_FOCUSED  (default 1) skip local notif+sound when terminal is frontmost
  CLAUDE_NOTIFY_MIN_DURATION           (default 0) suppress `stop` notif for turns shorter than N seconds
  CLAUDE_NOTIFY_TERMINAL_BUNDLE_ID     (macOS) override the terminal bundle id
  CLAUDE_NOTIFY_ICON                   (macOS) path/URL passed to terminal-notifier -appIcon
  CLAUDE_NOTIFY_RELAY                  (default 1) enable G2 relay
"""

import argparse
import hashlib
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import time
import urllib.request
from datetime import datetime

LOG_DIR = os.path.join(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")), "claude-notify")
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    filename=os.path.join(LOG_DIR, "notify.log"),
    format="%(asctime)s %(levelname)s %(message)s",
    level=logging.INFO,
)

NOTIFICATION_CONFIG = {
    "stop": {"message": "完了", "sound": "Glass"},
    "permission_prompt": {"message": "許可が必要", "sound": "Basso"},
    "idle_prompt": {"message": "入力待ち", "sound": "Ping"},
    "elicitation_dialog": {"message": "入力待ち", "sound": "Ping"},
    "elicitation_complete": {"message": "入力完了", "sound": "Pop"},
    "elicitation_response": {"message": "入力完了", "sound": "Pop"},
    "auth_success": {"message": "認証完了", "sound": "Pop"},
}
DEFAULT_CONFIG = {"message": "通知", "sound": "Pop"}

# macOS: TERM_PROGRAM -> bundle id (fallback when __CFBundleIdentifier is absent).
TERMINAL_BUNDLE_IDS = {
    "iTerm.app": "com.googlecode.iterm2",
    "Apple_Terminal": "com.apple.Terminal",
    "WezTerm": "com.github.wez.wezterm",
    "ghostty": "com.mitchellh.ghostty",
    "Ghostty": "com.mitchellh.ghostty",
    "vscode": "com.microsoft.VSCode",
    "Hyper": "co.zeit.hyper",
    "kitty": "net.kovidgoyal.kitty",
    "Alacritty": "org.alacritty",
    "Tabby": "org.tabby",
}

# macOS sound name -> freedesktop sound name (Linux)
LINUX_SOUND_MAP = {
    "Glass": "complete",
    "Basso": "dialog-warning",
    "Ping": "message-new-instant",
    "Pop": "message",
}

LINUX_URGENCY_MAP = {
    "permission_prompt": "critical",
    "stop": "normal",
}

RELAY_SERVER_URL = os.environ.get("RELAY_SERVER_URL", "http://localhost:3000")

MIN_SUBSTANTIAL_LENGTH = 80
MAX_BODY_LENGTH = 100


def env_flag(name: str, default: bool = True) -> bool:
    val = os.environ.get(name)
    if val is None:
        return default
    return val.strip().lower() not in ("0", "false", "no", "off", "")


# --------------------------------------------------------------------------- #
# Terminal / focus detection
# --------------------------------------------------------------------------- #

def _terminal_bundle_id() -> str:
    override = os.environ.get("CLAUDE_NOTIFY_TERMINAL_BUNDLE_ID")
    if override:
        return override
    bid = os.environ.get("__CFBundleIdentifier")
    if bid:
        return bid
    return TERMINAL_BUNDLE_IDS.get(os.environ.get("TERM_PROGRAM", ""), "")


def _frontmost_bundle_id_macos() -> str:
    try:
        asn = subprocess.run(
            ["lsappinfo", "front"], capture_output=True, text=True, timeout=2
        ).stdout.strip()
        if not asn:
            return ""
        out = subprocess.run(
            ["lsappinfo", "info", "-only", "bundleid", asn],
            capture_output=True, text=True, timeout=2,
        ).stdout.strip()
        match = re.search(r'=\s*"([^"]+)"', out)
        return match.group(1) if match else ""
    except Exception:
        return ""


def terminal_is_frontmost() -> bool:
    if sys.platform == "darwin":
        term = _terminal_bundle_id()
        return bool(term) and _frontmost_bundle_id_macos() == term
    return False


# --------------------------------------------------------------------------- #
# Transcript parsing
# --------------------------------------------------------------------------- #

def extract_assistant_text(entry: dict) -> str:
    content = entry.get("message", {}).get("content", [])
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


def last_human_prompt_epoch(transcript_path: str) -> float | None:
    try:
        with open(transcript_path, "r") as f:
            lines = f.readlines()
        for line in reversed(lines):
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("type") != "user" or entry.get("toolUseResult") is not None or entry.get("isMeta"):
                continue
            message = entry.get("message", {})
            if message.get("role") != "user":
                continue
            content = message.get("content")
            if isinstance(content, list) and any(
                isinstance(b, dict) and b.get("type") == "tool_result" for b in content
            ):
                continue
            ts = entry.get("timestamp")
            if not ts:
                continue
            try:
                return datetime.fromisoformat(ts.replace("Z", "+00:00")).timestamp()
            except ValueError:
                continue
        return None
    except Exception:
        return None


def should_suppress_for_duration(notification_type: str, transcript_path: str) -> bool:
    if notification_type != "stop" or not transcript_path:
        return False
    try:
        threshold = float(os.environ.get("CLAUDE_NOTIFY_MIN_DURATION", "0") or 0)
    except ValueError:
        return False
    if threshold <= 0:
        return False
    start = last_human_prompt_epoch(transcript_path)
    if start is None:
        return False
    return (time.time() - start) < threshold


# --------------------------------------------------------------------------- #
# Text shaping
# --------------------------------------------------------------------------- #

def summarize(text: str) -> str:
    if not text.strip():
        return ""
    clean = re.sub(r"```[\s\S]*?```", "", text)
    clean = re.sub(r"`[^`]+`", "", clean)
    clean = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", clean)
    clean = re.sub(r"[*_#>|~\-]+", "", clean)
    clean = re.sub(r"\s+", " ", clean).strip()
    for sep in ("。", "．", ". "):
        idx = clean.find(sep)
        if 0 < idx <= MAX_BODY_LENGTH:
            return clean[: idx + len(sep)]
    return clean if len(clean) <= MAX_BODY_LENGTH else clean[:MAX_BODY_LENGTH] + "…"


# --------------------------------------------------------------------------- #
# Desktop notification — macOS
# --------------------------------------------------------------------------- #

def _short_hash(text: str) -> str:
    return hashlib.md5((text or "").encode()).hexdigest()[:8]


def _applescript_quote(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def _notify_osascript(title: str, body: str) -> None:
    script = f"display notification {_applescript_quote(body)} with title {_applescript_quote(title)}"
    try:
        subprocess.run(["osascript", "-e", script], check=False, timeout=5)
    except Exception as e:
        logging.warning("osascript failed: %s", e)


def _notify_desktop_macos(notification_type: str, title: str, body: str, cwd: str) -> None:
    tn = shutil.which("terminal-notifier")
    if tn:
        group = f"claude-{notification_type}-{_short_hash(cwd)}"
        args = [tn, "-title", title, "-message", body or title, "-group", group]
        activate = _terminal_bundle_id()
        if activate:
            args += ["-activate", activate]
        icon = os.environ.get("CLAUDE_NOTIFY_ICON")
        if icon:
            args += ["-appIcon", icon]
        try:
            result = subprocess.run(args, capture_output=True, timeout=5)
            if result.returncode == 0:
                return
            logging.warning(
                "terminal-notifier rc=%s err=%s",
                result.returncode, result.stderr.decode(errors="replace")[:200],
            )
        except Exception as e:
            logging.warning("terminal-notifier failed: %s", e)
    _notify_osascript(title, body or title)


def _play_sound_macos(name: str) -> None:
    path = f"/System/Library/Sounds/{name}.aiff"
    if not os.path.exists(path):
        return
    try:
        subprocess.Popen(["afplay", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass


# --------------------------------------------------------------------------- #
# Desktop notification — Linux
# --------------------------------------------------------------------------- #

def _notify_desktop_linux(notification_type: str, title: str, body: str, _cwd: str) -> None:
    ns = shutil.which("notify-send")
    if not ns:
        logging.info("notify-send not found; skipping desktop notification")
        return
    urgency = LINUX_URGENCY_MAP.get(notification_type, "normal")
    args = [ns, "-u", urgency, "-a", "Claude Code", title]
    if body:
        args.append(body)
    try:
        subprocess.run(args, check=False, timeout=5)
    except Exception as e:
        logging.warning("notify-send failed: %s", e)


def _play_sound_linux(name: str) -> None:
    xdg_name = LINUX_SOUND_MAP.get(name, "message")
    for candidate in [
        f"/usr/share/sounds/freedesktop/stereo/{xdg_name}.oga",
        f"/usr/share/sounds/freedesktop/stereo/bell.oga",
    ]:
        if os.path.exists(candidate):
            player = shutil.which("paplay") or shutil.which("aplay")
            if player:
                try:
                    subprocess.Popen([player, candidate], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                except Exception:
                    pass
            return


# --------------------------------------------------------------------------- #
# Desktop notification — dispatcher
# --------------------------------------------------------------------------- #

def notify_desktop(notification_type: str, title: str, body: str, cwd: str) -> None:
    if sys.platform == "darwin":
        _notify_desktop_macos(notification_type, title, body, cwd)
    elif sys.platform == "linux":
        _notify_desktop_linux(notification_type, title, body, cwd)
    else:
        logging.info("no desktop notification support on %s", sys.platform)


def play_sound(name: str) -> None:
    if sys.platform == "darwin":
        _play_sound_macos(name)
    elif sys.platform == "linux":
        _play_sound_linux(name)


# --------------------------------------------------------------------------- #
# G2 glasses relay
# --------------------------------------------------------------------------- #

def send_relay_notification(notification_type: str, title: str, body: str) -> None:
    payload = json.dumps(
        {"type": notification_type, "title": title, "message": body if body else title}
    ).encode()
    req = urllib.request.Request(
        f"{RELAY_SERVER_URL}/api/notify", data=payload, headers={"Content-Type": "application/json"}
    )
    try:
        resp = urllib.request.urlopen(req, timeout=3)
        logging.info("relay sent status=%s", resp.status)
    except Exception as e:
        logging.debug("relay send skipped: %s", e)


# --------------------------------------------------------------------------- #
# Orchestration
# --------------------------------------------------------------------------- #

def send_notification(notification_type: str, hook_input: dict) -> None:
    config = NOTIFICATION_CONFIG.get(notification_type, DEFAULT_CONFIG)
    message = config["message"]
    cwd = hook_input.get("cwd") or os.getcwd()

    transcript_path = hook_input.get("transcript_path", "")
    if transcript_path:
        transcript_path = transcript_path.replace("~", os.path.expanduser("~"))

    if should_suppress_for_duration(notification_type, transcript_path):
        logging.info("suppressed (short task) type=%s", notification_type)
        return

    body = summarize(get_last_assistant_text(transcript_path)) if transcript_path else ""

    focused = env_flag("CLAUDE_NOTIFY_SUPPRESS_WHEN_FOCUSED", True) and terminal_is_frontmost()
    if focused:
        logging.info("local notification suppressed (terminal frontmost) type=%s", notification_type)
    else:
        notify_desktop(notification_type, message, body, cwd)
        play_sound(config["sound"])

    logging.info("type=%s title=%s focused=%s body=%s", notification_type, message, focused, body[:120])

    if env_flag("CLAUDE_NOTIFY_RELAY", True):
        send_relay_notification(notification_type, message, body)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--type", default="stop")
    args = parser.parse_args()

    hook_input = {}
    if not sys.stdin.isatty():
        try:
            hook_input = json.loads(sys.stdin.read())
        except (json.JSONDecodeError, ValueError):
            pass

    notification_type = hook_input.get("notification_type") or args.type
    send_notification(notification_type, hook_input)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.error("notify.py crashed: %s", e)
    sys.exit(0)
