# WSL2のgitが遅い対策
# checks to see if we are in a windows or linux dir
function isWinDir {
  case $PWD/ in
    /mnt/*) return $(true);;
    *) return $(false);;
  esac
}
# wrap the git command to either run windows git or linux
function git {
  if isWinDir
  then
    /mnt/c/Program\ Files/Git/mingw64/bin/git.exe "$@"
  else
    /usr/bin/git "$@"
  fi
}
function ghq-fzf() {
  local src=$(ghq list | fzf --preview "ls -laTp $(ghq root)/{} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}

# cd後にls
chpwd() { ls }

zle -N ghq-fzf
bindkey '^]' ghq-fzf
