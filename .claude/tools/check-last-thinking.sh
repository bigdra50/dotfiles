#!/bin/bash
# Check if the last assistant message contains a thinking block
# Uses timestamp to ensure chronological accuracy

if [ -z "$1" ]; then
  echo "Usage: $(basename "$0") <jsonl-file>" >&2
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Error: File '$1' not found" >&2
  exit 1
fi

# Extract assistant messages with timestamp, sort by timestamp, get last message's thinking status
jq -r 'select(.type == "assistant") |
       [.timestamp, (.message.content[]? | select(.type == "thinking") | "thinking")] |
       @tsv' "$1" \
  | sort -k1,1 \
  | tail -1 \
  | cut -f2
