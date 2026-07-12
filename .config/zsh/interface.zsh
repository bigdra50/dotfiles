# interface.zsh

# カスタム補完スクリプトを fpath に追加（compinit より前に必要）
fpath=("$ZDOTDIR/completions" $fpath)

# initialise completions with ZSH's compinit (1日1回だけ再構築)
# NOTE: extensions.zsh (sheldon 経由の fzf-tab) より前に compinit を済ませる必要が
#       あるため、このファイル (.zshrc で extensions より先に source) に置いている
autoload -Uz compinit
mkdir -p "$XDG_CACHE_HOME/zsh"
if [[ -n "$XDG_CACHE_HOME/zsh/zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
else
  compinit -C -d "$XDG_CACHE_HOME/zsh/zcompdump"
fi

case ${OSTYPE} in
  darwin*)
    export LSCOLORS=cxfxcxdxbxegedabagacad
    ;;
  linux*)
    eval $(dircolors -b ~/.colorrc)
    ;;
esac

# atuin - SQLite-based shell history
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh)"
fi

# Starship prompt
eval "$(starship init zsh)"

# OSC 7: cwdをパス文字列でターミナルに通知し、新ペイン/タブのCWD継承を堅牢化する。
# WezTermはOSC 7をプロセス検査(proc_pidinfo)より優先するため、
# 外部ボリューム抜去でカーネルcwdがdead vnode化しても、再マウント後は
# キャッシュ済みのパス文字列から正しいCWDで分割できる。
autoload -Uz add-zsh-hook
__osc7_notify_cwd() {
  emulate -L zsh
  [[ $TERM != dumb && -t 1 ]] || return
  local LC_ALL=C # バイト単位走査にする（日本語等のマルチバイトパス対応）
  local str=$PWD out='' ch i hex
  for (( i = 1; i <= ${#str}; i++ )); do
    ch=$str[i]
    case $ch in
      ([A-Za-z0-9_.~/-]) out+=$ch ;; # RFC3986 unreserved + '/'
      (*) hex=$(( [##16] #ch )); out+="%${(l:2::0:)hex}" ;;
    esac
  done
  printf '\e]7;file://%s%s\e\\' "$HOST" "$out"
}
add-zsh-hook chpwd __osc7_notify_cwd
__osc7_notify_cwd # chpwdは起動時に発火しないため初回は手動で発行

# 外部ボリューム抜去等でカーネルcwdが死んだ場合、$PWD(論理パス文字列)で張り直す。
# 正常時は何もしない（無条件cdはOLDPWDを毎回上書きし cd - を壊すため）。
_refresh_pwd() {
  [[ -e . ]] && return
  setopt localoptions no_auto_pushd
  builtin cd -- "$PWD" 2>/dev/null
}
precmd_functions+=(_refresh_pwd)

# vimキーバインドへ
bindkey -v
bindkey "jj" vi-cmd-mode

# ディレクトリ名だけで移動
setopt auto_cd  
# cd したら pushd
setopt auto_pushd
setopt pushd_ignore_dups
DIRSTACKSIZE=30
# コマンドラインでも#以降をコメントとみなす
setopt interactive_comments 
# 日本語ファイル名など8bitを通す
setopt print_eight_bit  
# 範囲指定できるようにする
# 例: mkdir {1-3}でフォルダ1, 2, 3を作れる
setopt brace_ccl

