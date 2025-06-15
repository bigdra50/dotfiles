Create a git commit with staged changes using gitmoji prefix and Japanese commit message.

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

3. **Do NOT include "Generated with Anthropic" or similar footer text**

4. **Analyze changes and create appropriate gitmoji with concise description**

Workflow:
1. Check `git status` and `git diff --staged` to understand changes
2. Analyze the nature of changes to select appropriate gitmoji
3. Create concise and clear Japanese commit message
4. Execute the commit

If $ARGUMENTS is provided, use it as reference for the commit message.