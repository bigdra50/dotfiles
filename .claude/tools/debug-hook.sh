#!/bin/bash

# Claude Code hook debug script
# This script logs all JSON input received by hooks for debugging purposes
# Usage: debug-hook.sh [hook_event_name]

HOOK_EVENT="${1:-unknown}"
LOG_DIR="$HOME/.claude/hook-logs"
LOG_FILE="$LOG_DIR/hook-${HOOK_EVENT}.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Read JSON input from stdin
JSON_INPUT=$(cat)

# Append JSON to event-specific log file (jq-compatible format)
echo "$JSON_INPUT" >> "$LOG_FILE"

# Exit successfully
exit 0