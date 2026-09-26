case ${OSTYPE} in
  darwin*)
    # Mac
    #alias ls="gls -FGS --group-directories-first"
    ;;
  linux*)
    # Linux(wsl)
    # c は abbr.zsh で claude に割り当てているので /mnt/c には張らない
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

alias .2='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
