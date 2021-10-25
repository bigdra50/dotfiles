#!/bin/sh

DOTPATH=~/dotfiles


init(){
  return 0
}

deploy(){
  cd DOTPATH
  if [$? -ne 0]; then
    die "not found: $DOTPATH"
  fi

  for f in .??*
  do
    ["$f" = ".git" -o "$f" = ".gitignore" ] && continue
    create_cymlink "$DOTPATH/$f" "$HOME/$f"
  done
}

create_cymlink(){
  ln -snfv "$1" "$2"
}

ostype(){
  uname | lower
}

detect_os(){
  export PLATFORM
  case "$(ostype)" in
    *'linux'*)  PLATFORM='linux'    ;;
    *'darwin'*) PLATFORM='osx'      ;;
    *)          PLATFORM='unknown'  ;;
  esac
}

is_osx(){
  detect_os
  if [ "$PLATFORM" = "osx" ]; then
    return 0
  else
    return 1
  fi
}

is_wsl(){
  if [ -f /proc/sys/fs/binfmt_misc/WSLInterop ]; then
    return 0
  else
    return 1
  fi
}

is_linux(){
  detect_os
  if ["$PLATFORM" = "linux"]; then
    return 0
  else
    return 1
  fi
}

lower(){
  if [ $# -eq 0 ]; then
    cat <&0
  elif [$# -eq 1]; then
    if [ -f "$1" -a -r "$1" ]; then
      cat "$1"
    else 
      echo "$1"
    fi
  else
    return 1
  fi | tr "[:upper:]" "[:lower:]"
}


upper(){
  if [ $# -eq 0 ]; then
    cat <&0
  elif [$# -eq 1]; then
    if [ -f "$1" -a -r "$1" ]; then
      cat "$1"
    else 
      echo "$1"
    fi
  else
    return 1
  fi | tr "[:lower:]" "[:upper:]"
}

e_newline(){
  printf "\n"
}

e_error() {
    printf " \033[31m%s\033[m\n" "✖ $*" 1>&2
}

die(){
  e_error "$1" >&2
  exit "${2:-1}"
}

