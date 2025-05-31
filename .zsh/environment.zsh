# environment.zsh
#[[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] && . ~/.nix-profile/etc/profile.d/nix.sh
# mise (formerly rtx) - Development tools version manager
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
elif [[ -f ~/.local/bin/mise ]]; then
  eval "$(~/.local/bin/mise activate zsh)"
fi
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


# Go environment setup (mise will handle go installation)
if command -v go &> /dev/null; then
  export GOPATH=$(go env GOPATH)
  export PATH=$PATH:$(go env GOPATH)/bin
fi

