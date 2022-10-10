case ${OSTYPE} in
  darwin*)
    # Mac
    #alias ls="gls -FGS --group-directories-first"
    ;;
  linux*)
    # Linux(wsl)
    alias c='/mnt/c'
    alias d='/mnt/d'
    alias e='/mnt/e'
    #alias ls='LC_COLLATE=C ls --color=auto --group-directories-first'
    alias exp='explorer.exe'
    alias open='cmd.exe /c start'
    alias clip='clip.exe'
    alias adb='adb.exe'
    cd ~
    ;;
esac

alias cp='cp -r'
alias mkdir='mkdir -p'
alias rm='trash -rf'
alias cut='choose'
alias df='duf'
alias du='dust'

alias g='git'

DOTFILES=$XDG_DATA_HOME/chezmoi
alias v='nvim'
alias vz='vim $DOTFILES/dot_zshrc'
alias vv='vim $DOTFILES/dot_config/nvim/init.vim'
alias h='history'
alias so='source'
alias soz='source $HOME/.zshenv && source $HOME/.zshrc'
#alias mkdir='(){mkdir $1;cd $1}'
