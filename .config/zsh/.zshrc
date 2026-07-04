# Show system info on startup (optional)
#command -v neofetch &>/dev/null && neofetch
[[ -f "$ZDOTDIR/environment.zsh" ]] && . "$ZDOTDIR/environment.zsh"
[[ -f "$ZDOTDIR/interface.zsh" ]] && . "$ZDOTDIR/interface.zsh"
[[ -f "$ZDOTDIR/extensions.zsh" ]] && . "$ZDOTDIR/extensions.zsh"

[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env

# ローカルオーバーライドは最後に読む (alias/function/plugin を上書きできるように)
[[ -f "$ZDOTDIR/.zshrc_local" ]] && . "$ZDOTDIR/.zshrc_local"