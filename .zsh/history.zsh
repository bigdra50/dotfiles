# -------------------------------
# history
# -------------------------------

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=100000
# 重複するコマンドなら､古いものを削除
setopt hist_ignore_all_dups
# 重複を記録しない
setopt hist_ignore_dups
setopt share_history
setopt append_history
# 保管時に履歴を自動的に展開
setopt hist_expand
# 履歴をインクリメンタルに追加
setopt inc_append_history
# historyコマンドは履歴に登録しない
setopt hist_no_store
# 余分な空白は削除
setopt hist_reduce_blanks
zstyle ':completion:*:default' menu select

## history検索
### Ctrl-P/Ctlr-Nで,入力中の文字から始まるコマンドの履歴が表示
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end
bindkey "^R" history-incremental-search-backward

function history-all { history -E 1 }
