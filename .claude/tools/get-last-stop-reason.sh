#!/bin/bash
# Get the last assistant message's stop_reason from a jsonl file
# Uses timestamp to ensure chronological accuracy

if [ -z "$1" ]; then
  echo "Usage: $(basename "$0") <jsonl-file>" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Error: File '$1' not found" >&2
  exit 1
fi

# Extract assistant messages with timestamp, sort by timestamp, get last stop_reason
jq -r 'select(.type == "assistant") | [.timestamp, .message.stop_reason // "null"] | @tsv' "$1" \
  | sort -k1,1 \
  | tail -1 \
  | cut -f2
