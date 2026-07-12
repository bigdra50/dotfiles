# Functions

hascmd(){
  [[ -x $(which "$1") ]]
}

isDebian(){
  uname -v | grep Debian
}

sshf(){
  local selected
  selected=$(
    awk '/^Host[ \t]/ { for (i = 2; i <= NF; i++) if ($i !~ /[*?]/) print $i }' \
      ~/.ssh/config ~/.ssh/config.d/*.conf(N) 2>/dev/null \
      | sort -u \
      | while read -r h; do
          # ssh -G はInclude解決後の最終設定を出力する(接続はしない)
          # User=git のホストはgit forge用aliasなので候補から除外
          ssh -G "$h" 2>/dev/null | awk -v h="$h" '
            $1 == "user" { u = $2 }
            $1 == "hostname" { hn = $2 }
            END { if (u != "git") printf "%s\t%s@%s\n", h, u, hn }'
        done \
      | column -t -s $'\t' \
      | fzf --prompt='ssh > ' \
            --preview 'ssh -G {1} | grep -E "^(hostname|user|port|identityfile|proxyjump) "' \
            --preview-window=down,5,wrap
  ) || return
  ssh "${selected%% *}"
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
