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

install_mise:
    #!/usr/bin/env bash
    if command -v mise &> /dev/null; then
        echo "mise is already installed at $(which mise)"
    else
        curl https://mise.run | sh
        echo 'mise installed successfully!'
    fi

setup_mise_tools:
    #!/usr/bin/env bash
    # Install tools using mise
    mise use --global go@latest
    mise use --global rust@latest
    mise use --global node@latest
    mise use --global neovim@nightly
    
    # Install cargo/go tools
    mise exec -- cargo install ghq
    mise exec -- cargo install delta
    mise exec -- cargo install ripgrep
    mise exec -- cargo install lsd
    mise exec -- go install mvdan.cc/sh/v3/cmd/shfmt@latest
    
    # Install fzf separately
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all --no-bash --no-fish

install_starship:
    #!/usr/bin/env bash
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo 'starship installed successfully!'

install: clone link_dotfiles
    #!/usr/bin/env bash
    echo "dotfiles installation completed!"
