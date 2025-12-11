# for fzf

export FZF_DEFAULT_OPTS="--bind=ctrl-k:kill-line --bind=ctrl-space:toggle --reverse"

pop(){ 
  cd $(dirs -lp | bat -r 2: | fzf --no-sort --prompt='cd >') 
}

select-history() {
  LBUFFER=$(history -Dinr 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > " | choose 3:)
}

ghq-fzf() {
  local src=$(ghq list | fzf --preview "ls -laTp $(ghq root)/{} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}

zle -N ghq-fzf
bindkey '^]' ghq-fzf

# fzf 標準キーバインドと補完を読み込み（Ctrl-T, Ctrl-R, Alt-C）
# fzf 0.48.0+ の推奨方法: fzf --zsh を使用
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi
