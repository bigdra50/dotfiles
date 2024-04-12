# environment.zsh
#[[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] && . ~/.nix-profile/etc/profile.d/nix.sh
. "$HOME/.asdf/asdf.sh"
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


. ~/.asdf/plugins/golang/set-env.zsh

export GOPATH=$(go env GOPATH)
export PATH=$PATH:$(go env GOPATH)/bin

