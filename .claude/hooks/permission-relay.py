#!/usr/bin/env python3
"""PermissionRequest hook: relay to G2 glass via WebSocket relay server.

Sends permission request to relay server, waits for glass user response.
Outputs hookSpecificOutput JSON to stdout.
Falls through (no output) if relay server is unavailable — normal CLI prompt appears.
"""

import json
import logging
import os
import sys
import urllib.request

LOG_DIR = os.path.join(
    os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")),
    "bark-notify",
)
os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    filename=os.path.join(LOG_DIR, "permission-relay.log"),
    format="%(asctime)s %(levelname)s %(message)s",
    level=logging.INFO,
)

RELAY_SERVER_URL = os.environ.get("RELAY_SERVER_URL", "http://localhost:3000")


def main() -> None:
    hook_input: dict = {}
    if not sys.stdin.isatty():
        try:
            hook_input = json.loads(sys.stdin.read())
        except (json.JSONDecodeError, ValueError):
            pass

    tool_name = hook_input.get("tool_name", "unknown")
    tool_input = hook_input.get("tool_input", {})

    logging.info("permission request: tool=%s", tool_name)

    payload = json.dumps({
        "tool_name": tool_name,
        "tool_input": tool_input,
    }).encode()

    req = urllib.request.Request(
        f"{RELAY_SERVER_URL}/api/permission-request",
        data=payload,
        headers={"Content-Type": "application/json"},
    )

    try:
        resp = urllib.request.urlopen(req, timeout=58)
        result = json.loads(resp.read().decode())
        decision = result.get("decision", "deny")
        logging.info("permission response: decision=%s", decision)

        output: dict = {
            "hookSpecificOutput": {
                "hookEventName": "PermissionRequest",
                "decision": {
                    "behavior": decision,
                },
            }
        }
        if decision == "deny":
            output["hookSpecificOutput"]["decision"]["message"] = "G2グラスから拒否"
        print(json.dumps(output))
    except Exception as e:
        # Relay server unavailable or timeout — fall through silently
        logging.info("relay unavailable, falling through: %s", e)


if __name__ == "__main__":
    main()
