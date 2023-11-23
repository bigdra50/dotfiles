# environment.zsh
[[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] && . ~/.nix-profile/etc/profile.d/nix.sh
echo ${ASDF_DIR}
. "$HOME/.asdf/asdf.sh"
echo ${ASDF_DIR}
# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit && compinit

case ${OSTYPE} in
  darwin*)
    export LSCOLORS=cxfxcxdxbxegedabagacad
    ;;
  linux*)
    eval $(dircolors -b ~/.colorrc)
    ;;
esac

