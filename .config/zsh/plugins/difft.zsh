# difftastic: AST-aware diff (delta との併用)
# delta をメイン pager に維持し、difft はオンデマンドで使用
alias gdd='GIT_EXTERNAL_DIFF=difft git diff'
alias gdl='GIT_EXTERNAL_DIFF=difft git log -p'
