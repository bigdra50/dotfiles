# OS別の設定
case ${OSTYPE} in
  darwin*)
    # Mac
    #alias ls="LC_COLLATE=C gls --group-directories-first"
    ;;
  linux*)
    # Linux(wsl)
    # pyenv
    if [ ! -e "$HOME/.pyenv" ]; then
      git clone https://github.com/pyenv/pyenv.git ~/.pyenv
    fi
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    #if command -v pyenv 1>/dev/null 2>&1; then
      eval "$(pyenv init --path)"
    #fi
    # end pyenv
    
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_CACHE_HOME="$HOME/.cache"
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    export PATH="{$PATH}:/c/Program Files/Git LFS"
    export PATH=$PATH:/opt/gradle/gradle-6.3/bin  # gradleのパス
    export PATH=$PATH:/mnt/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2019/Community/Common7/IDE/CommonExtensions/Microsoft/FSharp/


    alias c='/mnt/c'
    alias d='/mnt/d'
    alias e='/mnt/e'
    alias ls='LC_COLLATE=C ls --color=auto --human-readable --group-directories-first'
    alias exp='explorer.exe'
    alias open='cmd.exe /c start'
    alias clip='clip.exe'
    alias adb='adb.exe'
    cd ~
    ;;
esac

alias ll="ls -lh"
alias la="ls -a"
alias lal='ls -al'

alias v='nvim'
alias vz='nvim ~/.zshrc'
alias vp='nvim ~/.zpreztorc'
alias vv='nvim ~/.config/nvim/init.vim'
alias h='history'
alias sshz='ssh s1260133@sshgate.u-aizu.ac.jp'
alias sshzy='ssh -Y s1260133@sshgate.u-aizu.ac.jp'
alias sshpi='ssh bigdra@raspberrypi -p 22 -i ~/.ssh/id_ed25519'
alias sftpz='sftp s1260133@sshgate.u-aizu.ac.jp'
alias scpz='scp s1260133@sshgate.u-aizu.ac.jp:/home/student/s1260133/'
alias so='source'
alias soz='source ~/.zshenv && source ~/.zshrc'
#alias mkdir='(){mkdir $1;cd $1}'
