# commented alias should be skipped
#alias ls='ls -la'

alias quoted_single='echo one'
alias quoted_double="echo two"
alias .2=cd ../..

case ${OSTYPE} in
  linux*)
    alias c='/mnt/c'
    alias exp='explorer.exe'
    ;;
esac

alias -g L='|bat --style=plain'
