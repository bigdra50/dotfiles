#!/bin/sh

DOTPATH=~/dotfiles

has() {
  type "$1" > /dev/null 2>&1
}

if [ ! -d ${DOTPATH} ]; then
  if has "git"; then
    git clone https://github.com/bigdra50/dotfiles.git
  elif has "curl" || has "wget"; then
    TARBALL="https://github.com/bigdra50/dotfiles/archive/master.tar.gz"
    if has "curl"; then
      curl -L ${TARBALL} -o master.tar.gz
    else
      wget ${TARBALL}
    fi
    tar -zxvf master.tar.gz
    rm -f master.tar.gz
    mv -f dotfiles-master "${DOTPATH}"
  else
    echo "echo or wget or git required"
    exit 1
  fi
  cd ${DOTPATH}

  for f in .??*
  do
    [[ "$f" == ".git" ]] && continue
    [[ "$f" == ".gitignore" ]] && continue
    [[ "$f" == ".DS_Store" ]] && continue
    
    ln -snf "$DOTPATH/$f" "$HOME/$f"
  done
  for f in *
  do
    [[ "$f" == ".git" ]] && continue
    [[ "$f" == ".gitignore" ]] && continue
    [[ "$f" == ".DS_Store" ]] && continue
    [[ "$f" == "README.md" ]] && continue
    [[ "$f" == "install.sh" ]] && continue
    [[ "$f" == "nvim" ]] && mkdir -p $HOME/.config/ && ln -sf "$DOTPATH/.config/nvim" "$HOME/.config/nvim" && continue
    ln -sf "$DOTPATH/$f" "$HOME/$f"
    echo "Installed $f"
  done

else
  echo "dotfiles already exists"
  exit 1
fi
