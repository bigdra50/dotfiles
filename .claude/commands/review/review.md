---
allowed-tools: [Bash, Read, Grep, Glob, TodoWrite]
description: Analyze staged code changes and provide feedback in Critical, Minor, and Nits categories
model: sonnet
---

Run `git status` and `git diff --cached`, then analyze the code changes and the files as a whole.
Provide feedback in the 3 following sections:

- Critical ❌
- Minor 🟡
- Nits 🟢
