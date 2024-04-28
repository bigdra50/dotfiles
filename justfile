#!/usr/bin/env just --justfile

default:
    @echo "no default task"

# GitHub リポジトリの URL

REPO_URL := "https://github.com/bigdra50/dotfiles.git"

# dotfiles のディレクトリ

DOTFILES_DIR := "$HOME/.ghq/github.com/bigdra50/dotfiles"

# 除外するファイルとディレクトリのリスト

BLACKLIST := ". .. .git README.md install.sh justfile"

# dotfiles をクローンする
clone:
    #!/usr/bin/env bash
    if [[ ! -d "{{ DOTFILES_DIR }}" ]]; then
      echo "Cloning dotfiles repository..."
      mkdir -p "{{ DOTFILES_DIR }}"
      git clone "{{ REPO_URL }}" "{{ DOTFILES_DIR }}"
    else
      echo "dotfiles directory already exists. Skipping clone."
     fi

# シンボリックリンクを作成する
create_symlink source target:
    #!/usr/bin/env bash
    if [[ -e "{{ target }}" ]]; then
        echo "File or directory '{{ target }}' already exists."
        while true; do
            read -p "Overwrite or ignore? (O/i) " answer
            case $answer in
                [Oo]* ) ln -sf "{{ source }}" "{{ target }}"; break;;
                [Ii]* ) echo "Ignoring '{{ target }}'"; break;;
                * ) echo "Please answer overwrite (O) or ignore (i).";;
            esac
        done
    else
        ln -s "{{ source }}" "{{ target }}"
        echo "Created symlink: {{ source }} -> {{ target }}"
    fi

# ホームディレクトリにシンボリックリンクを作成する

link_dotfiles:
    #!/usr/bin/env bash
    for file in {{ DOTFILES_DIR }}/.*; do
        if [[ -e "$file" && ! " {{ BLACKLIST }} " =~ " $(basename "$file") " ]]; then
            TARGET="$HOME/$(basename "$file")"
            echo "Target: ${TARGET}"
            just create_symlink "$file" "$TARGET"
        fi
    done

install_asdf:
    #!/usr/bin/env bash
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
    . "$HOME/.asdf/asdf.sh"
    . "$HOME/.asdf/completions/asdf.bash"

add_asdf_plugins:
    #!/usr/bin/env bash
    asdf update
    asdf plugin add ghq
    asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
    asdf plugin-add rust https://github.com/asdf-community/asdf-rust.git
    asdf plugin add neovim
    asdf plugin add fzf https://github.com/kompiro/asdf-fzf.git
    asdf plugin add delta
    asdf plugin add nodejs
    asdf plugin add ripgrep
    asdf plugin add shfmt
    asdf plugin add lsd https://github.com/ossareh/asdf-lsd.git

    asdf install ghq latest
    asdf install golang latest
    asdf install rust latest
    asdf install neovim nightly
    asdf install fzf latest
    asdf install delta latest
    asdf install nodejs latest
    asdf install ripgrep latest
    asdf install shfmt latest
    asdf install lsd latest

    asdf global ghq latest
    asdf global golang latest
    asdf global rust latest
    asdf global neovim nightly
    asdf global fzf latest
    asdf global delta latest
    asdf global nodejs latest
    asdf global ripgrep latest
    asdf global shfmt latest
    asdf global lsd latest

install: clone link_dotfiles
    #!/usr/bin/env bash
    echo "dotfiles installation completed!"
