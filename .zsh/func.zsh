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

# cd後にls
chpwd() { ls }
