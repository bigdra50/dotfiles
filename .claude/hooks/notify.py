#!/usr/bin/env python3
"""Claude Code notification hook."""

import argparse
import subprocess
import sys

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


def send_notification(notification_type: str) -> None:
    """Send notification with terminal-notifier and play sound."""
    config = NOTIFICATION_CONFIG.get(notification_type, DEFAULT_CONFIG)

    # Send notification with Claude icon
    subprocess.run(
        [
            "terminal-notifier",
            "-title", config["title"],
            "-message", config["message"],
            "-group", f"claude-code-{notification_type}",
            "-sender", "com.anthropic.claudefordesktop",
        ],
        check=True,
    )

    # Play sound
    subprocess.Popen(
        ["afplay", f"/System/Library/Sounds/{config['sound']}.aiff"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


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
