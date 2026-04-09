# interface.zsh
# Starship prompt
eval "$(starship init zsh)"

# WezTermペイン分割後にPWDのfdが古くなり、Starshipがread_only誤検出する対策
_refresh_pwd() {
  setopt localoptions no_auto_pushd
  cd "$(pwd)" 2>/dev/null
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

