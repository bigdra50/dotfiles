# Show system info on startup (optional)
#command -v neofetch &>/dev/null && neofetch
[[ -f ~/.zsh/environment.zsh ]] && . ~/.zsh/environment.zsh
[[ -f ~/.zshrc_local ]] && . ~/.zshrc_local
[[ -f ~/.zsh/interface.zsh ]] && . ~/.zsh/interface.zsh
[[ -f ~/.zsh/extensions.zsh ]] && . ~/.zsh/extensions.zsh

