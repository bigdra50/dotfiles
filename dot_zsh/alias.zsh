case ${OSTYPE} in
  darwin*)
    # Mac
    alias ls="gls -FGS --group-directories-first"
    ;;
  linux*)
    # Linux(wsl)
    alias c='/mnt/c'
    alias d='/mnt/d'
    alias e='/mnt/e'
    alias ls='LC_COLLATE=C ls --color=auto --group-directories-first'
    alias exp='explorer.exe'
    alias open='cmd.exe /c start'
    alias clip='clip.exe'
    alias adb='adb.exe'
    cd ~
    ;;
esac

alias ls="ls -F"
alias ll="ls -lh"
alias la="ls -a"
alias lal='ls -al'

alias rm='trash -rf'
alias cp='cp -r'
alias mkdir='mkdir -p'

alias g='git'


if hascmd nvim; then
  alias vim='nvim'
fi

alias v='vim'
alias vz='vim ~/.zshrc'
alias vv='vim ~/.config/nvim/init.vim'
alias h='history'
alias so='source'
alias soz='source ~/.zshenv && source ~/.zshrc'
#alias mkdir='(){mkdir $1;cd $1}'
