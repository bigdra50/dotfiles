#!/bin/bash

# Unity activation script for C# file edits
# This script activates Unity when a .cs file is edited

# Check if the tool used was Edit and if it involved a .cs file
if [[ "$CLAUDE_TOOL_NAME" == "Edit" && "$CLAUDE_TOOL_INPUT" == *".cs"* ]]; then
    echo "C# file edited, activating Unity..."
    osascript -e 'tell application "Unity" to activate'
fi