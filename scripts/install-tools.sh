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
# TOML Parser
# =============================================================================

parse_toml_array() {
    local section="$1"
    local file="$2"

    awk -v section="$section" '
        BEGIN { in_section = 0 }
        /^\[/ { in_section = 0 }
        $0 ~ "^\\[" section "\\]" { in_section = 1; next }
        in_section && /name = / {
            gsub(/.*name = "|".*/, "")
            print
        }
    ' "$file"
}

# =============================================================================
# Installation Functions
# =============================================================================

install_go_tools() {
    info "Installing Go tools..."

    local max_retries=5
    local retry=0
    while ! command_exists go && [ $retry -lt $max_retries ]; do
        warning "Go not found. Waiting for Go installation... (attempt $((retry+1))/$max_retries)"
        sleep 2
        eval "$(mise activate bash)" 2>/dev/null || true
        export PATH="$HOME/.local/bin:$PATH:$(go env GOPATH)/bin" 2>/dev/null || true
        retry=$((retry+1))
    done

    if ! command_exists go; then
        error "Go not found. Please install Go first."
        return 1
    fi

    local tools=($(parse_toml_array "go_tools" "$TOOLS_FILE"))

    if [[ ${#tools[@]} -eq 0 ]]; then
        info "No go tools specified in tools.toml"
        return 0
    fi

    export GOPATH="$(go env GOPATH)"
    export PATH="$PATH:$GOPATH/bin"

    for tool in "${tools[@]}"; do
        local binary_name="${tool##*/}"
        binary_name="${binary_name%@*}"

        if command_exists "$binary_name"; then
            success "$binary_name already installed"
        else
            info "Installing $tool..."
            export GOPROXY="https://proxy.golang.org,direct"
            export GOSUMDB="sum.golang.org"
            export GOPRIVATE=""

            local max_retries=3
            local retry=0
            while [ $retry -lt $max_retries ]; do
                if go install "$tool"; then
                    success "$binary_name installed successfully"
                    break
                else
                    retry=$((retry+1))
                    if [ $retry -lt $max_retries ]; then
                        warning "Failed to install $tool, retrying... ($retry/$max_retries)"
                        sleep 3
                    else
                        error "Failed to install $tool after $max_retries attempts"
                    fi
                fi
            done
        fi
    done
}

install_cargo_tools() {
    info "Installing Cargo tools..."

    local max_retries=5
    local retry=0
    while ! command_exists cargo && [ $retry -lt $max_retries ]; do
        warning "Cargo not found. Waiting for Rust installation... (attempt $((retry+1))/$max_retries)"
        sleep 2
        eval "$(mise activate bash)" 2>/dev/null || true
        export PATH="$HOME/.local/bin:$PATH:$HOME/.cargo/bin"
        retry=$((retry+1))
    done

    if ! command_exists cargo; then
        error "Cargo not found. Please install Rust first."
        return 1
    fi

    if ! command_exists cargo-binstall; then
        info "Installing cargo-binstall for faster installations..."
        cargo install cargo-binstall
    fi

    local tools=($(parse_toml_array "cargo" "$TOOLS_FILE"))

    if [[ ${#tools[@]} -eq 0 ]]; then
        info "No cargo tools specified in tools.toml"
        return 0
    fi

    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            success "$tool already installed"
        else
            info "Installing $tool..."
            local tool_name="$tool"
            local version_arg=""

            local tool_version=$(awk -v tool="$tool" '
                /name = "/ && $0 ~ ("\"" tool "\"") {
                    if (/version = /) {
                        match($0, /version = "[^"]*"/)
                        version_part = substr($0, RSTART, RLENGTH)
                        gsub(/version = "|"/, "", version_part)
                        print version_part
                        exit
                    }
                }
            ' "$TOOLS_FILE")

            if [[ -n "$tool_version" && "$tool_version" != "latest" ]]; then
                version_arg="--version $tool_version"
            fi

            local install_success=false

            if command_exists cargo-binstall; then
                info "Trying fast binary installation for $tool_name..."

                if [[ -n "${GITHUB_TOKEN:-}" ]] || [[ -n "${GH_TOKEN:-}" ]]; then
                    export BINSTALL_GH_API_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN}}"
                fi

                if [[ -z "$version_arg" ]]; then
                    binstall_cmd="cargo binstall -y --no-confirm --log-level warn $tool_name"
                else
                    binstall_cmd="cargo binstall -y --no-confirm --log-level warn $tool_name $version_arg"
                fi

                if timeout 30s $binstall_cmd; then
                    success "$tool_name installed successfully (binary)"
                    install_success=true
                else
                    warning "Binary installation timed out or failed for $tool_name"
                fi
            fi

            if [[ "$install_success" == false ]]; then
                info "Binary installation failed, compiling from source..."
                if [[ -z "$version_arg" ]]; then
                    install_cmd="cargo install $tool_name"
                else
                    install_cmd="cargo install $tool_name $version_arg"
                fi

                if $install_cmd; then
                    success "$tool_name installed successfully (compiled)"
                else
                    error "Failed to install $tool_name"
                fi
            fi
        fi
    done
}

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
    if [[ -f "$DOTFILES_DIR/.config/mise/config.toml" ]] || [[ -f "$DOTFILES_DIR/.mise.toml" ]]; then
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
    install_go_tools
    install_cargo_tools

    success "Tool installation completed!"
}

main "$@"
