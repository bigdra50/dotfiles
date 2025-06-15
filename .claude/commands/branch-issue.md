Create a feature branch from a GitHub issue.

Workflow:
1. Fetch issue details: `gh issue view $ARGUMENTS --json title,labels,number`
2. Extract issue title and clean it for branch naming
3. Generate branch name: `feature/issue-<number>-<title-slug>`
   - Convert title to lowercase slug (replace spaces/special chars with hyphens)
   - Limit to reasonable length (50 chars max)
4. Check if branch already exists
5. Sync with main/master branch: `git pull origin main`
6. Create and switch to new branch: `git checkout -b <branch-name>`
7. Set upstream: `git push -u origin <branch-name>`
8. Show branch creation summary with issue link

Error handling:
- Invalid issue number or issue not found
- Branch name conflicts
- Uncommitted changes (offer to stash)
- Network issues with GitHub API

Usage: `claude /branch-issue 123`
$ARGUMENTS should contain the issue number.