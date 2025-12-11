---
allowed-tools:
  - Bash(git:*)
  - Read
  - Grep
  - Glob
description: Read all files changed in the current git branch to catch up on recent work
---

# catchup - Catch up on branch changes

Reads all files that have been modified, added, or renamed in the current git branch compared to the base branch (main/master/develop).

## Workflow

1. **Detect base branch**
   - Check for main, master, or develop branch

2. **Get changed files**
   - Find all modified, added, and renamed files
   - Exclude deleted files

3. **Read all changed files**
   - Read each file in parallel for efficiency
   - Display summary of changes

4. **Provide context**
   - Summarize the nature of changes
   - Highlight key modifications

## Usage

```
/catchup
```

The command automatically detects the appropriate base branch and reads all changed files.
