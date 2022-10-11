# -------------------------------
# history
# -------------------------------

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=100000
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt share_history
setopt append_history
setopt inc_append_history
setopt hist_no_store
setopt hist_reduce_blanks
zstyle ':completion:*:default' menu select

## history����
### Ctrl-P/Ctlr-N��,���͒��̕�������n�܂�R�}���h�̗������\��
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end
bindkey "^R" history-incremental-search-backward
