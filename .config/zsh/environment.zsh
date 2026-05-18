# environment.zsh
#[[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] && . ~/.nix-profile/etc/profile.d/nix.sh
# mise (formerly rtx) - Development tools version manager
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh --shims)"
elif [[ -f ~/.local/bin/mise ]]; then
  eval "$(~/.local/bin/mise activate zsh --shims)"
fi
# カスタム補完スクリプトを fpath に追加（compinit より前に必要）
fpath=("$ZDOTDIR/completions" $fpath)

# initialise completions with ZSH's compinit (1日1回だけ再構築)
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


# Go environment setup (mise will handle go installation)
if command -v go &> /dev/null; then
  export GOPATH=$(go env GOPATH)
  export PATH=$PATH:$GOPATH/bin
fi

# dotnet tools (/etc/paths.d/dotnet-cli-tools contains literal "~/.dotnet/tools";
# path_helper does not expand it, so PATH lookup fails. Prepend the resolved path.)
if command -v dotnet &> /dev/null; then
  export PATH=$PATH:$HOME/.dotnet/tools
fi

# atuin - SQLite-based shell history
if command -v atuin &> /dev/null; then
  eval "$(atuin init zsh)"
fi

# cc-worklog: task-mgr に出力先を向ける
export CC_WORKLOG_DIR="/Users/USER/workspace/task-mgr"

