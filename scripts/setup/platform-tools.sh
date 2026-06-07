#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TOOLS_FILE="$DOTFILES_DIR/tools.toml"
source "$DOTFILES_DIR/scripts/lib.sh"

PLATFORM=$(detect_platform)

# ---- Platform-specific tools ----

install_macos_tools() {
    if ! command_exists brew; then return; fi

    info "Installing macOS tools via Homebrew..."
    # while-read instead of mapfile: this runs on stock macOS bash 3.2,
    # which predates mapfile (bash 4.0)
    local brew_tools=()
    while IFS= read -r line; do
        brew_tools+=("$line")
    done < <(awk '/\[platform.macos\]/,/brew_cask/ {
        if (/^[[:space:]]*"/ && !/brew_cask/) {
            gsub(/[[:space:]]*"|".*/, "")
            print
        }
    }' "$TOOLS_FILE")

    for tool in "${brew_tools[@]}"; do
        if brew list "$tool" &>/dev/null; then
            success "$tool already installed"
        else
            brew install "$tool"
        fi
    done

    info "Installing macOS cask applications..."
    local brew_casks=()
    while IFS= read -r line; do
        brew_casks+=("$line")
    done < <(awk '/brew_cask = \[/,/\]/ {
        if (/^[[:space:]]*"/) {
            gsub(/[[:space:]]*"|".*/, "")
            print
        }
    }' "$TOOLS_FILE")

    for cask in "${brew_casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            success "$cask already installed (cask)"
        else
            info "Installing cask: $cask..."
            brew install --cask "$cask" || warning "Failed to install cask: $cask"
        fi
    done
}

install_linux_tools() {
    if ! command_exists apt-get; then return; fi

    info "Installing Linux/WSL tools via apt..."
    local essential_tools=("cmake" "pkg-config" "libssl-dev" "build-essential" "curl" "git" "zsh")

    local platform_tools=()
    if [[ "$PLATFORM" == "wsl" ]]; then
        while IFS= read -r line; do
            platform_tools+=("$line")
        done < <(awk '/\[platform.wsl\]/,/\[/ {
            if (/^[[:space:]]*"/ && !/\[/) {
                gsub(/[[:space:]]*"|".*/, "")
                print
            }
        }' "$TOOLS_FILE")
    fi

    local all_tools=("${essential_tools[@]}" "${platform_tools[@]}")
    local to_install=()

    for tool in "${all_tools[@]}"; do
        if dpkg -l "$tool" &>/dev/null; then
            success "$tool already installed"
        else
            to_install+=("$tool")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Installing: ${to_install[*]}"
        sudo apt-get update
        sudo apt-get install -y "${to_install[@]}"
    fi
}

# ---- mise ----

install_mise() {
    if ! command_exists mise; then
        info "Installing mise..."
        curl https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
    else
        success "mise already installed"
    fi
}

install_mise_runtimes() {
    if ! command_exists mise; then
        error "mise not found"
        return 1
    fi

    eval "$(mise activate bash)"
    export PATH="$HOME/.local/bin:$PATH"

    if [[ -f "$DOTFILES_DIR/.config/mise/config.toml" ]]; then
        info "Installing mise tools..."
        cd "$DOTFILES_DIR"

        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            export GITHUB_TOKEN
        fi

        if ! mise install; then
            warning "mise install failed. Trying without neovim nightly..."
            sed -i.bak 's/neovim = "nightly"/neovim = "stable"/' .config/mise/config.toml
            mise install
            mv .config/mise/config.toml.bak .config/mise/config.toml
        fi
    fi

    eval "$(mise activate bash)"
    success "Mise runtimes installed"
}

# ---- Fallback tools ----

install_fallback_tools() {
    if ! command_exists fzf; then
        if command_exists brew; then
            brew install fzf
        else
            if [[ -d "$HOME/.fzf" ]]; then
                cd "$HOME/.fzf" && git pull
            else
                git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
            fi
            "$HOME/.fzf/install" --all --no-bash --no-fish --no-update-rc
        fi
    else
        success "fzf already installed"
    fi

    if ! command_exists uv; then
        if command_exists brew; then
            brew install uv
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
    else
        success "uv already installed"
    fi
}

# ---- Main ----

info "Detected platform: $PLATFORM"

case "$PLATFORM" in
    macos) install_macos_tools ;;
    wsl | linux) install_linux_tools ;;
esac

install_mise
install_mise_runtimes
install_fallback_tools

success "Platform tools installation completed"
