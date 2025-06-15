Create a feature branch based on current changes analysis.

Workflow:
1. Analyze current changes: `git status` and `git diff`
2. Identify modified files and change patterns
3. Generate descriptive branch name based on:
   - File types changed (e.g., "config", "docs", "api")
   - Change nature (e.g., "add", "fix", "update")
   - Specific components modified
4. Suggest branch name format: `feature/<type>-<description>`
5. Check if branch already exists
6. Sync with main/master branch: `git pull origin main`
7. Create and switch to new branch: `git checkout -b <branch-name>`
8. Set upstream: `git push -u origin <branch-name>`
9. Show branch creation summary

Error handling:
- No changes detected
- Branch name conflicts
- Uncommitted changes (offer to stash)

Usage: `claude /branch-current`
If $ARGUMENTS is provided, use it as additional context for branch naming.