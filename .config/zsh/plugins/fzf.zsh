# for fzf

export FZF_DEFAULT_OPTS="--bind=ctrl-k:kill-line --bind=ctrl-space:toggle --reverse"

pop(){ 
  cd $(dirs -lp | bat -r 2: | fzf --no-sort --prompt='cd >') 
}

# ghq list はリポジトリルート(外付けドライブ)の全走査で数秒〜33s かかるため結果をキャッシュする。
# Ctrl+] はキャッシュから即 fzf 表示し、古い(>10分)ときだけ裏で非同期に全走査し直す。
# 全走査の合間の clone と削除は、表示の直前に _ghq_list_cached が補正する。

# キャッシュの更新時刻は走査の開始時刻にそろえる。
# 走査が owner を通り過ぎた後に clone されたリポジトリを、_ghq_list_cached に拾わせるため。
_ghq_cache_rebuild() {
  emulate -LR zsh
  local cache=$1 started scanned
  started=$(mktemp "$cache.XXXXXX") || return
  scanned=$(mktemp "$cache.XXXXXX") || { rm -f -- $started; return 1 }
  ghq list >| $scanned 2>/dev/null && touch -r $started $scanned && mv -f -- $scanned $cache
  rm -f -- $started $scanned
}

# clone や削除をすると、親の owner ディレクトリ(host/owner)の更新時刻が変わる。
# キャッシュより新しい owner だけ、直下のリポジトリを .git の有無で数え直す(git 以外の VCS は使っていない)。
# ghq list は使わない。owner 単位でも git 管理外の Unity プロジェクトなどを深く走査し、数秒かかるため。
# owner の更新時刻に表れない変化(owner 直下より深い階層での増減、owner ごとの削除)は裏の全走査に任せる。
_ghq_list_cached() {
  emulate -LR zsh
  local root=$1 cache=$2 owner rel entry repo
  local -a repos gone found
  [[ -r $cache ]] || return 0
  repos=( ${(f)"$(<$cache)"} )
  for owner in $root/*/*(N/e:'[[ $REPLY -nt $cache ]]':); do
    rel=${owner#$root/}
    for entry in ${(M)repos:#$rel/*}; do
      [[ -e $root/$entry ]] || gone+=( $entry )
    done
    for repo in $owner/*(N/); do
      [[ -e $repo/.git ]] && found+=( $rel/${repo:t} )
    done
  done
  repos=( ${repos:|gone} ${found:|repos} )
  (( $#repos )) || return 0
  # ghq list と同じバイト順にそろえる
  local LC_ALL=C
  print -rl -- ${(o)repos}
}

ghq-fzf() {
  local root cache src
  root=$(ghq root)
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/ghq-list"

  # 初回（キャッシュ無し）のみブロックして生成
  [[ -s $cache ]] || _ghq_cache_rebuild "$cache"

  # 10分より古いときだけ裏で全走査する（外付けドライブへの多重走査を防ぐ）
  if [[ -z $(find "$cache" -mmin -10 2>/dev/null) ]]; then
    _ghq_cache_rebuild "$cache" &>/dev/null &!
  fi

  src=$(_ghq_list_cached "$root" "$cache" | fzf --preview "ls -la $root/{} 2>/dev/null")
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
