#!/usr/bin/env python3
"""Claude Code notification hook using OSC escape sequences and Bark push."""

import argparse
import os
import subprocess
import sys
import urllib.request
import urllib.parse

# Configuration per notification type
NOTIFICATION_CONFIG = {
    "stop": {
        "title": "Claude Code",
        "message": "作業が完了しました",
        "sound": "Glass",
    },
    "idle_prompt": {
        "title": "Claude Code",
        "message": "入力を待っています",
        "sound": "Ping",
    },
    "permission_prompt": {
        "title": "Claude Code",
        "message": "許可が必要です",
        "sound": "Basso",
    },
}

DEFAULT_CONFIG = {
    "title": "Claude Code",
    "message": "通知",
    "sound": "Pop",
}

BARK_CONTAINER_NAME = "bark-server"
BARK_PORT = "8090"


def ensure_bark_server() -> bool:
    """Start bark-server Docker container if not running. Returns True if available."""
    try:
        result = subprocess.run(
            ["docker", "inspect", "-f", "{{.State.Running}}", BARK_CONTAINER_NAME],
            capture_output=True, text=True, timeout=5,
        )
        if result.stdout.strip() == "true":
            return True
        # Container exists but stopped
        subprocess.run(
            ["docker", "start", BARK_CONTAINER_NAME],
            capture_output=True, timeout=10,
        )
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False
    except Exception:
        return False


def send_bark_notification(title: str, message: str) -> None:
    """Send push notification via Bark server."""
    bark_key = os.environ.get("BARK_KEY")
    if not bark_key:
        return

    if not ensure_bark_server():
        return

    hostname = subprocess.run(
        ["scutil", "--get", "LocalHostName"],
        capture_output=True, text=True, timeout=5,
    ).stdout.strip()

    base_url = f"http://{hostname}.local:{BARK_PORT}"
    encoded_title = urllib.parse.quote(title)
    encoded_message = urllib.parse.quote(message)
    url = f"{base_url}/{bark_key}/{encoded_title}/{encoded_message}"

    try:
        urllib.request.urlopen(url, timeout=5)
    except Exception:
        pass


def send_notification(notification_type: str) -> None:
    """Send notification using osascript (macOS built-in) and Bark push."""
    config = NOTIFICATION_CONFIG.get(notification_type, DEFAULT_CONFIG)
    title = config["title"]
    message = config["message"]

    # Use osascript for reliable notification on macOS
    subprocess.run(
        [
            "osascript",
            "-e",
            f'display notification "{message}" with title "{title}"',
        ],
        check=False,
    )

    # Play sound (afplay is macOS built-in)
    subprocess.Popen(
        ["afplay", f"/System/Library/Sounds/{config['sound']}.aiff"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    # Send Bark push notification to iPhone
    send_bark_notification(title, message)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--type",
        choices=["stop", "idle_prompt", "permission_prompt"],
        required=True,
    )
    args = parser.parse_args()

    send_notification(args.type)


if __name__ == "__main__":
    if sys.platform == "darwin":
        main()
