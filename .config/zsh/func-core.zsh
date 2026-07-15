# func-core.zsh - 常時層の関数 (対話/非対話を問わず必要なもの)
#
# $ZDOTDIR/.zshenv から source される。Claude Code のツールシェルやスクリプトの
# `zsh -c` でも効かせたい関数だけを置く。対話専用 (fzf 等の UI を伴うもの) は
# func.zsh (extensions.zsh 経由 = .zshrc チェーン) に置くこと。

#
# for gh (GitHub CLI)
#
# cwd の org ディレクトリごとに GH_CONFIG_DIR を出し分けてアカウントを固定する。
# トークンは keyring 共有なので各 config dir は hosts.yml だけでよい。
# 具体的な org→config dir の対応は連想配列 GH_ORG_CONFIG で与える。
# 職場など公開できない対応は非追跡の .zshenv_local 側で定義すること:
#   typeset -gA GH_ORG_CONFIG=( github.com/<org> gh-<config-dir> ... )
# GH_ORG_CONFIG 未定義/不一致ならデフォルト ($XDG_CONFIG_HOME/gh) にフォールバックする。
gh(){
  local base="${XDG_CONFIG_HOME:-$HOME/.config}" k cfg=""
  if (( ${+GH_ORG_CONFIG} )); then
    for k in ${(k)GH_ORG_CONFIG}; do
      case $PWD/ in
        */$k/*) cfg="$base/${GH_ORG_CONFIG[$k]}"; break ;;
      esac
    done
  fi
  if [[ -n $cfg ]]; then
    GH_CONFIG_DIR="$cfg" command gh "$@"
  else
    command gh "$@"
  fi
}

#
# for markserv (Markdown プレビューサーバ)
#
# ghq 管理の git 版 (1.18.0: hotreload が ws 化され livereload 専用ポート廃止) を
# ラップする。npm 版 1.17.4 は 35729 固定でポート競合しやすいため。
# - 基準ポート(既定 8642)が使用中なら 1 つずつずらして空き HTTP ポートで起動
# - 同じディレクトリを配信中なら起動せず既存 URL を返す
# markserv は process.title を書き換え argv が ps から読めないため、配信中判定は
# 状態ファイル ($XDG_STATE_HOME/markserv/<dirハッシュ>) で行う。
# git 版が無い (外付けドライブ未マウント等) ときは PATH 上の mise 版へフォールバック。
markserv(){
  setopt localoptions nomonitor local_traps
  local repo=/Volumes/CrucialX9/dev/github.com/markserv/markserv
  local cli="$repo/lib/cli.js"
  [[ -f $cli ]] || { command markserv "$@"; return }

  # 先頭の非フラグ引数だけを配信 dir とみなす (値を取るフラグの値を誤認しない)。
  # 残りは基準ポート(-p/--port)を抜き出しつつ markserv へそのまま渡す。
  local dir=""
  [[ $# -gt 0 && $1 != -* ]] && { dir=$1; shift }
  local base=8642
  local -a passthru
  while (( $# )); do
    case $1 in
      -p|--port) base=${2:-8642}; shift; (( $# )) && shift ;;
      --port=*)  base=${1#--port=}; shift ;;
      -p*)       base=${1#-p}; shift ;;
      *)         passthru+=("$1"); shift ;;
    esac
  done
  local cdir=${${dir:-$PWD}:A}   # 絶対パス・symlink 解決

  # 状態ファイル: 配信 dir のハッシュ名に pid/port/dir を記録
  local sdir=${XDG_STATE_HOME:-$HOME/.local/state}/markserv
  mkdir -p $sdir
  local hash=$(print -rn -- $cdir | shasum)
  local sf=$sdir/${hash[1,16]}

  # 同じ dir を配信中なら起動済みを返す (pid 生存 + プロセス名 + port listen で検証)
  if [[ -f $sf ]]; then
    local spid sport
    { read -r spid; read -r sport } < $sf
    if kill -0 $spid 2>/dev/null \
       && [[ $(ps -o command= -p $spid 2>/dev/null) == *markserv* ]] \
       && lsof -nP -iTCP:$sport -sTCP:LISTEN >/dev/null 2>&1; then
      print -ru2 -- "markserv: 起動済み $cdir -> http://localhost:$sport (pid $spid)"
      return 0
    fi
    rm -f $sf   # stale
  fi

  # 基準ポートから 1 つずつずらして空き HTTP ポートを探す
  local port=$base
  while lsof -nP -iTCP:$port -sTCP:LISTEN >/dev/null 2>&1; do
    (( ++port > 65535 )) && { print -ru2 -- "markserv: 空きポートなし"; return 1 }
  done
  (( port != base )) && print -ru2 -- "markserv: port $base 使用中 -> $port で起動"

  # 起動 (pid 取得と状態記録のため背景実行 -> wait。Ctrl+C で停止 + 状態掃除)
  node "$cli" "$cdir" -p $port "${passthru[@]}" &
  local npid=$!
  print -rl -- $npid $port $cdir > $sf
  trap "kill $npid 2>/dev/null; rm -f ${(q)sf}" INT TERM
  wait $npid
  rm -f $sf
}
