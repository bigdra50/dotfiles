# for fzf

export FZF_DEFAULT_OPTS="--bind=ctrl-k:kill-line --bind=ctrl-space:toggle --reverse"

pop(){ 
  cd $(dirs -lp | bat -r 2: | fzf --no-sort --prompt='cd >') 
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

# gh + fzf: 自分のリポジトリ
gh-my-fzf() {
  local repo=$(gh repo list --limit 200 --json nameWithOwner -q '.[].nameWithOwner' | fzf --prompt="my repos > ")
  if [ -n "$repo" ]; then
    BUFFER="gh repo view --web $repo"
    zle accept-line
  fi
  zle -R -c
}
zle -N gh-my-fzf
bindkey '^\' gh-my-fzf

# gh + fzf: GitHub全体を検索
gh-search-fzf() {
  local repo=$(: | fzf --prompt="gh search > " \
    --bind "change:reload:gh search repos {q} --limit 30 --json fullName -q '.[].fullName' 2>/dev/null || true" \
    --phony)
  if [ -n "$repo" ]; then
    BUFFER="gh repo view --web $repo"
    zle accept-line
  fi
  zle -R -c
}
zle -N gh-search-fzf
bindkey '^Xs' gh-search-fzf

# fzf 標準キーバインドと補完を読み込み（Ctrl-T, Ctrl-R, Alt-C）
# fzf 0.48.0+ の推奨方法: fzf --zsh を使用
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi
