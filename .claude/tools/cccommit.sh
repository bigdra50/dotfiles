#!/bin/bash

# Execute git commit command using Claude Code SDK with staged changes prompt
PROMPT="Create a git commit with staged changes using gitmoji prefix and Japanese commit message.

Follow these rules:

1. **Use gitmoji as prefix (GitHub shortcode format)**

   - :sparkles: New features
   - :bug: Bug fixes
   - :memo: Documentation updates
   - :recycle: Refactoring
   - :zap: Performance improvements
   - :art: Code structure/format improvements
   - :wrench: Configuration file changes
   - :white_check_mark: Adding/updating tests
   - :rocket: Deployment/releases
   - :lock: Security fixes

2. **Write commit message in Japanese**
3. **Analyze changes and create appropriate gitmoji with concise description**
4. **includeCoAuthoredBy: false**

Workflow:

1. Check \`git status\` and \`git diff --staged\` to understand changes
2. Analyze the nature of changes to select appropriate gitmoji
3. Create concise and clear Japanese commit message
4. Execute the commit

If \$ARGUMENTS is provided, use it as reference for the commit message."

claude -p "$PROMPT" --model sonnet --allowedTools "Bash(git status:*)" "Bash(git diff:*)" "Bash(git commit:*)" "Bash(git log:*)" --disallowedTools "Bash(git add:*)" "Bash(git reset:*)" "Bash(git rm:*)" "Bash(git mv:*)" "Bash(git checkout:*)" "Bash(git branch:*)" "Bash(git merge:*)" "Bash(git rebase:*)" "Bash(git push:*)" "Bash(git pull:*)" "Bash(git fetch:*)" "Bash(git clone:*)" --output-format stream-json --verbose | jq -r 'if .type == "assistant" and .message.content then .message.content[] | select(.type == "text") | .text elif .type == "result" then .result else empty end'
