# Functions

hascmd(){
  [[ -x $(which "$1") ]]
}

isDebian(){
  uname -v | grep Debian
}

sshf(){
    host=$(cat ~/.ssh/config | grep 'Host ' | cut -d ' ' -f 2 | fzf)
  if [[ "$?" -eq 0 ]]; then
    ssh $host
  fi
}

# WSL2のgitが遅い対策
# checks to see if we are in a windows or linux dir
isWinDir() {
  case $PWD/ in
    /mnt/*) return $(true);;
    *) return $(false);;
  esac
}

mkcd(){
  [ $# -gt 0 ] || {
    echo "Usage: mkcd [option] dirname" 1>&2; return 1;
  };
  mkdir "$@" && {
    while [ $# -gt 1 ]; do shift; done; cd "$1";
  };
}


# 
# for Unity
#
unity-version(){
  cat ProjectSettings/ProjectVersion.txt | grep "m_EditorVersion:" | awk -F" " '{print $2 }'
}

uadb(){
  eval "/Applications/Unity/Hub/Editor/$(unity-version)/PlaybackEngines/AndroidPlayer/SDK/platform-tools/adb" $@
}
