# Show system info on startup (optional)
#command -v neofetch &>/dev/null && neofetch
[[ -f "$ZDOTDIR/environment.zsh" ]] && . "$ZDOTDIR/environment.zsh"
[[ -f "$ZDOTDIR/.zshrc_local" ]] && . "$ZDOTDIR/.zshrc_local"
[[ -f "$ZDOTDIR/interface.zsh" ]] && . "$ZDOTDIR/interface.zsh"
[[ -f "$ZDOTDIR/extensions.zsh" ]] && . "$ZDOTDIR/extensions.zsh"


[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env