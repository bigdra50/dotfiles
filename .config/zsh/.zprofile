# login shell: /etc/zprofile (path_helper) が PATH を再構成した後に正準順序を再主張する。
# 定義の実体は env.zsh (冪等)。ここに定義を直接置かないこと。
[[ -f "$ZDOTDIR/env.zsh" ]] && . "$ZDOTDIR/env.zsh"
