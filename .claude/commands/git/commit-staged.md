---
allowed-tools: ["Bash(git:*)", "Read"]
description: Create a git commit with gitmoji prefix and Japanese message for staged changes
model: claude-sonnet-4-0
---

# Create a git commit with staged changes using gitmoji prefix and Japanese commit message

## Context

- Current git status: !`git status`
- Current git diff(staged): !`git diff --staged`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

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

Workflow:

1. Based on above context, understand changes
2. Analyze the nature of changes to select appropriate gitmoji
3. Create concise and clear Japanese commit message
4. Execute the commit

If $ARGUMENTS is provided, use it as reference for the commit message.
