#!/usr/bin/env bash
# =============================================================================
# Unified Tool Installation Script
# Reads tools.toml and installs tools based on platform
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
TOOLS_FILE="$DOTFILES_DIR/tools.toml"

# Logging functions
info() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
warning() { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1" >&2; }

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse TOML file (simple parser for our use case)
parse_toml_array() {
    local section="$1"
    local file="$2"
    
    # Extract the section and parse tool names
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

# Install go tools
install_go_tools() {
    info "Installing Go tools..."
    
    # Wait for go to be available (retry mechanism)
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
    
    # Parse tools from TOML
    local tools=($(parse_toml_array "go_tools" "$TOOLS_FILE"))
    
    if [[ ${#tools[@]} -eq 0 ]]; then
        info "No go tools specified in tools.toml"
        return 0
    fi
    
    # Set up Go environment
    export GOPATH="$(go env GOPATH)"
    export PATH="$PATH:$GOPATH/bin"
    
    for tool in "${tools[@]}"; do
        # Extract binary name from go module path
        local binary_name="${tool##*/}"
        binary_name="${binary_name%@*}"
        
        if command_exists "$binary_name"; then
            success "$binary_name already installed"
        else
            info "Installing $tool..."
            # Set Go proxy environment variables for better reliability
            export GOPROXY="https://proxy.golang.org,direct"
            export GOSUMDB="sum.golang.org"
            export GOPRIVATE=""
            
            # Retry mechanism for go install
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

# Install cargo tools
install_cargo_tools() {
    info "Installing Cargo tools..."
    
    # Wait for cargo to be available (retry mechanism)
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
    
    # Install cargo-binstall for faster binary downloads
    if ! command_exists cargo-binstall; then
        info "Installing cargo-binstall for faster installations..."
        cargo install cargo-binstall
    fi
    
    # Parse tools from TOML
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
            # Extract tool name and version from TOML parsing
            local tool_name="$tool"
            local version_arg=""
            
            # Check if version is specified in tools.toml
            local tool_version=$(awk -v tool="$tool" '
                /name = "/ && $0 ~ ("\"" tool "\"") {
                    # Look for version in the same line, exact match only
                    if (/version = /) {
                        match($0, /version = "[^"]*"/)
                        version_part = substr($0, RSTART, RLENGTH)
                        gsub(/version = "|"/, "", version_part)
                        print version_part
                        exit  # Exit after first match to avoid duplicates
                    }
                }
            ' "$TOOLS_FILE")
            
            if [[ -n "$tool_version" && "$tool_version" != "latest" ]]; then
                version_arg="--version $tool_version"
            fi
            
            # Try cargo binstall first for faster installation
            local install_success=false
            
            if command_exists cargo-binstall; then
                info "Trying fast binary installation for $tool_name..."
                
                # Set GitHub token if available to avoid rate limits
                if [[ -n "${GITHUB_TOKEN:-}" ]] || [[ -n "${GH_TOKEN:-}" ]]; then
                    export BINSTALL_GH_API_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN}}"
                fi
                
                # Don't pass version for binstall if it's "latest" or empty
                if [[ -z "$version_arg" ]]; then
                    binstall_cmd="cargo binstall -y --no-confirm --log-level warn $tool_name"
                else
                    binstall_cmd="cargo binstall -y --no-confirm --log-level warn $tool_name $version_arg"
                fi
                
                # Try binstall with timeout to avoid long waits on rate limits
                if timeout 30s $binstall_cmd; then
                    success "$tool_name installed successfully (binary)"
                    install_success=true
                else
                    warning "Binary installation timed out or failed for $tool_name"
                fi
            fi
            
            # Fallback to cargo install if binstall fails
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

# Install mise if not exists
install_mise() {
    if ! command_exists mise; then
        info "Installing mise..."
        curl https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
        
        # Verify installation
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

# Install mise runtimes
install_mise_runtimes() {
    info "Setting up mise runtimes..."
    
    if ! command_exists mise; then
        error "mise not found. Please run install_mise first."
        return 1
    fi
    
    # Trust mise configuration files
    info "Trusting mise configuration files..."
    mise trust "$DOTFILES_DIR/.mise.toml" || true
    mise trust "$DOTFILES_DIR/.config/mise/config.toml" || true
    
    # Activate mise environment
    info "Activating mise environment..."
    eval "$(mise activate bash)"
    export PATH="$HOME/.local/bin:$PATH"
    
    # Install tools from .mise.toml
    if [[ -f "$DOTFILES_DIR/.mise.toml" ]]; then
        info "Installing tools from .mise.toml..."
        cd "$DOTFILES_DIR"
        
        # Export GitHub token if available
        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            export GITHUB_TOKEN
            info "Using GitHub token for API requests"
        else
            warning "No GitHub token found. Rate limits may apply."
        fi
        
        # Install with retry on rate limit
        if ! mise install; then
            warning "mise install failed. Trying without neovim nightly..."
            # Temporarily remove neovim nightly if it fails
            sed -i.bak 's/neovim = "nightly"/neovim = "stable"/' .mise.toml
            mise install
            # Restore original
            mv .mise.toml.bak .mise.toml
        fi
    fi
    
    # Install tools from .config/mise/config.toml
    if [[ -f "$DOTFILES_DIR/.config/mise/config.toml" ]]; then
        info "Installing tools from .config/mise/config.toml..."
        cd "$DOTFILES_DIR"
        mise install
    fi
    
    # Re-activate mise to ensure new tools are in PATH
    eval "$(mise activate bash)"
    success "Mise runtimes installed and activated"
}

# Install platform-specific tools
install_platform_tools() {
    local platform="$1"

    case "$platform" in
        macos)
            if command_exists brew; then
                info "Installing macOS tools via Homebrew..."
                # Extract brew packages
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

                # Install brew cask packages
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
                
                # Essential build tools for Rust cargo installations
                essential_tools=("cmake" "pkg-config" "libssl-dev" "build-essential" "curl" "git" "zsh")
                
                # Extract platform-specific apt packages if any
                platform_tools=()
                if [[ "$platform" == "wsl" ]]; then
                    platform_tools=($(awk '/\[platform.wsl\]/,/\[/ { 
                        if (/^[[:space:]]*"/ && !/\[/) {
                            gsub(/[[:space:]]*"|".*/, "")
                            print
                        }
                    }' "$TOOLS_FILE"))
                fi
                
                # Combine essential and platform-specific tools
                all_tools=("${essential_tools[@]}" "${platform_tools[@]}")
                
                # Check which packages need installation
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
            echo "Run: powershell -ExecutionPolicy Bypass -File scripts/Install-Tools.ps1"
            ;;
    esac
}

# Install fallback tools (for environments without brew)
install_fallback_tools() {
    info "Checking fallback tools..."

    # fzf - install if not available and brew is not present
    if ! command_exists fzf; then
        if command_exists brew; then
            info "Installing fzf via Homebrew..."
            brew install fzf
        else
            info "Installing fzf from git..."
            if [[ -d "$HOME/.fzf" ]]; then
                success "fzf directory exists, updating..."
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

    # uv - install if not available
    if ! command_exists uv; then
        if command_exists brew; then
            info "Installing uv via Homebrew..."
            brew install uv
        else
            info "Installing uv via installer..."
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
        success "uv installed"
    else
        success "uv already installed"
    fi
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *) echo "unknown" ;;
    esac
}

# Main function
main() {
    if [[ ! -f "$TOOLS_FILE" ]]; then
        error "tools.toml not found at $TOOLS_FILE"
        exit 1
    fi
    
    local platform=$(detect_platform)
    info "Detected platform: $platform"
    
    # Install in order of priority
    install_platform_tools "$platform"  # Install build tools first
    install_mise
    install_mise_runtimes
    install_fallback_tools  # fzf, uv etc.
    install_go_tools
    install_cargo_tools

    success "Tool installation completed!"
}

# Run main
main "$@"