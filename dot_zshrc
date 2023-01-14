# Init nix
[[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] && . ~/.nix-profile/etc/profile.d/nix.sh

[[ -f ~/.zsh/zinit.zsh ]] && . ~/.zsh/zinit.zsh
[[ -f ~/.zsh/func.zsh ]] && . ~/.zsh/func.zsh
[[ -f ~/.zsh/history.zsh ]] && . ~/.zsh/history.zsh
[[ -f ~/.p10k.zsh ]] && . ~/.p10k.zsh

[[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]] && . "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"

# wslのrcファイルでこの設定をするとGUI描画時に古いOpenGLが使われてしまうことがあるため､ unsetしている
# wsl以外の環境ではいらない?
# unset LIBGL_ALWAYS_INDIRECT
 
case ${OSTYPE} in
  darwin*)
    export LSCOLORS=cxfxcxdxbxegedabagacad
    ;;
  linux*)
    eval $(dircolors -b ~/.colorrc)
    ;;
esac
 
 
# vimキーバインドへ
bindkey -v
bindkey "jj" vi-cmd-mode

setopt auto_cd  # ディレクトリ名だけで移動
setopt auto_pushd  # cd したら pushd
setopt pushd_ignore_dups
setopt interactive_comments # コマンドラインでも#以降をコメントとみなす
setopt print_eight_bit  # 日本語ファイル名など8bitを通す
# 範囲指定できるようにする
# 例: mkdir {1-3}でフォルダ1, 2, 3を作れる
setopt brace_ccl

if hascmd brew; then
  [[ -f $(brew --prefix asdf)/libexec/asdf.sh ]] && . $(brew --prefix asdf)/libexec/asdf.sh
fi

# load plugins config
while read -d $'\0' f; do
  [[ -f ${f} ]] && . ${f}
done < <(find ~/.zsh/plugins -mindepth 1 -maxdepth 1 -print0)

[[ -f ~/.zsh/completion.zsh ]] && . ~/.zsh/completion.zsh
[[ -f ~/.zsh/alias.zsh ]] && . ~/.zsh/alias.zsh          

[[ -f ~/.zshrc_local ]] && . ~/.zshrc_local
neofetch
