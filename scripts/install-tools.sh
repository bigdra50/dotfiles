#!/usr/bin/env bash
# =============================================================================
# Unified Tool Installation Script
# Reads tools.toml and installs tools based on platform
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
TOOLS_FILE="$DOTFILES_DIR/tools.toml"

# Source shared library
source "$SCRIPT_DIR/lib.sh"

# =============================================================================
# Installation Functions
# =============================================================================

install_mise() {
    if ! command_exists mise; then
        info "Installing mise..."
        curl https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"

        if command_exists mise; then
            success "mise installed successfully"
        else
            error "Failed to install mise"
            return 1
        fi
    else
        success "mise already installed"
    fi
}

install_mise_runtimes() {
    info "Setting up mise runtimes..."

    if ! command_exists mise; then
        error "mise not found. Please run install_mise first."
        return 1
    fi

    # Activate mise environment
    info "Activating mise environment..."
    eval "$(mise activate bash)"
    export PATH="$HOME/.local/bin:$PATH"

    # Install tools from config files
    if [[ -f "$DOTFILES_DIR/.config/mise/config.toml" ]]; then
        info "Installing mise tools..."
        cd "$DOTFILES_DIR"

        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            export GITHUB_TOKEN
            info "Using GitHub token for API requests"
        else
            warning "No GitHub token found. Rate limits may apply."
        fi

        if ! mise install; then
            warning "mise install failed. Trying without neovim nightly..."
            sed -i.bak 's/neovim = "nightly"/neovim = "stable"/' .config/mise/config.toml
            mise install
            mv .config/mise/config.toml.bak .config/mise/config.toml
        fi
    fi

    eval "$(mise activate bash)"
    success "Mise runtimes installed and activated"
}

install_platform_tools() {
    local platform="$1"

    case "$platform" in
        macos)
            if command_exists brew; then
                info "Installing macOS tools via Homebrew..."
                local brew_tools=($(awk '/\[platform.macos\]/,/brew_cask/ {
                    if (/^[[:space:]]*"/ && !/brew_cask/) {
                        gsub(/[[:space:]]*"|".*/, "")
                        print
                    }
                }' "$TOOLS_FILE"))

                for tool in "${brew_tools[@]}"; do
                    if brew list "$tool" &>/dev/null; then
                        success "$tool already installed"
                    else
                        brew install "$tool"
                    fi
                done

                info "Installing macOS cask applications..."
                local brew_casks=($(awk '/brew_cask = \[/,/\]/ {
                    if (/^[[:space:]]*"/) {
                        gsub(/[[:space:]]*"|".*/, "")
                        print
                    }
                }' "$TOOLS_FILE"))

                for cask in "${brew_casks[@]}"; do
                    if brew list --cask "$cask" &>/dev/null; then
                        success "$cask already installed (cask)"
                    else
                        info "Installing cask: $cask..."
                        brew install --cask "$cask" || warning "Failed to install cask: $cask"
                    fi
                done
            fi
            ;;
        wsl|linux)
            if command_exists apt-get; then
                info "Installing Linux/WSL tools via apt..."

                essential_tools=("cmake" "pkg-config" "libssl-dev" "build-essential" "curl" "git" "zsh")

                platform_tools=()
                if [[ "$platform" == "wsl" ]]; then
                    platform_tools=($(awk '/\[platform.wsl\]/,/\[/ {
                        if (/^[[:space:]]*"/ && !/\[/) {
                            gsub(/[[:space:]]*"|".*/, "")
                            print
                        }
                    }' "$TOOLS_FILE"))
                fi

                all_tools=("${essential_tools[@]}" "${platform_tools[@]}")

                to_install=()
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
            fi
            ;;
        windows)
            warning "Windows detected. Please run Install-Tools.ps1 in PowerShell instead."
            ;;
    esac
}

install_fallback_tools() {
    info "Checking fallback tools..."

    if ! command_exists fzf; then
        if command_exists brew; then
            info "Installing fzf via Homebrew..."
            brew install fzf
        else
            info "Installing fzf from git..."
            if [[ -d "$HOME/.fzf" ]]; then
                cd "$HOME/.fzf" && git pull
            else
                git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
            fi
            "$HOME/.fzf/install" --all --no-bash --no-fish --no-update-rc
        fi
        success "fzf installed"
    else
        success "fzf already installed"
    fi

    if ! command_exists uv; then
        if command_exists brew; then
            brew install uv
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
        success "uv installed"
    else
        success "uv already installed"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    if [[ ! -f "$TOOLS_FILE" ]]; then
        error "tools.toml not found at $TOOLS_FILE"
        exit 1
    fi

    local platform=$(detect_platform)
    info "Detected platform: $platform"

    install_platform_tools "$platform"
    install_mise
    install_mise_runtimes
    install_fallback_tools

    success "Tool installation completed!"
}

main "$@"
