# Show system info on startup (optional)
#command -v neofetch &>/dev/null && neofetch
[[ -f "$ZDOTDIR/interface.zsh" ]] && . "$ZDOTDIR/interface.zsh"
[[ -f "$ZDOTDIR/extensions.zsh" ]] && . "$ZDOTDIR/extensions.zsh"

# ローカルオーバーライドは最後に読む (alias/function/plugin を上書きできるように)
[[ -f "$ZDOTDIR/.zshrc_local" ]] && . "$ZDOTDIR/.zshrc_local"