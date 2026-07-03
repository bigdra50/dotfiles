# for fzf

export FZF_DEFAULT_OPTS="--bind=ctrl-k:kill-line --bind=ctrl-space:toggle --reverse"

pop(){ 
  cd $(dirs -lp | bat -r 2: | fzf --no-sort --prompt='cd >') 
}

# ghq list はリポジトリルート(外付けドライブ)の全走査で ~33s かかるため結果をキャッシュする。
# Ctrl+] はキャッシュから即 fzf 表示し、古い(>10分)ときだけ裏で非同期に更新する。
ghq-fzf() {
  local root cache src
  root=$(ghq root)
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/ghq-list"

  # 初回（キャッシュ無し）のみブロックして生成
  [[ -s $cache ]] || ghq list > "$cache"

  # 10分より古いときだけ裏で更新（外付けドライブへの多重走査を防ぐ）
  if [[ -z $(find "$cache" -mmin -10 2>/dev/null) ]]; then
    ( ghq list > "$cache.tmp" 2>/dev/null && mv -f "$cache.tmp" "$cache" ) &!
  fi

  src=$(fzf < "$cache" --preview "ls -la $root/{} 2>/dev/null")
  if [ -n "$src" ]; then
    BUFFER="cd $root/$src"
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
