Analyze the current Claude conversation to identify implemented code/files, stage them for git, confirm with user, then create a git commit with gitmoji prefix and Japanese commit message.

Follow these rules:

1. **Identify implemented files from conversation**

   - Scan the conversation history for files that were created, modified, or implemented
   - Look for code blocks, file operations, and implementation discussions
   - Focus on actual deliverables and working code

2. **Stage identified files with confirmation**

   - List all files that would be staged
   - Show a preview of what changes would be committed
   - Ask user for explicit confirmation before staging
   - Only proceed if user confirms

3. **Use gitmoji as prefix (GitHub shortcode format)**

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

4. **Write commit message in Japanese**

5. **DO NOT include "Generated with Anthropic" or similar footer text**

6. **Analyze conversation context for appropriate commit message**

Workflow:

1. Analyze current conversation to identify implemented files/changes
2. Check `git status` to see current repository state
3. List files that would be staged based on conversation analysis
4. Show `git diff` preview for identified files
5. Ask user: "以下のファイルをステージングしてコミットしますか？" with file list
6. Wait for user confirmation (y/n)
7. If confirmed:
   - Stage the identified files with `git add`
   - Analyze the nature of changes to select appropriate gitmoji
   - Create concise and clear Japanese commit message based on conversation context
   - Execute the commit
8. If not confirmed, abort gracefully

If $ARGUMENTS is provided, use it as additional context for the commit message.
