#
# for fzf
#
# 並び替え無しでプロンプトに'cd > 'を表示
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
