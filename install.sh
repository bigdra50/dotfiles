#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installation Script
# =============================================================================
# This script installs and configures dotfiles on a new machine
#
# Usage:
#   ./install.sh                    # Interactive installation
#   INTERACTIVE=false ./install.sh  # Non-interactive installation
#   ./install.sh --help             # Show help

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"

# Interactive mode flag
INTERACTIVE="${INTERACTIVE:-true}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# File exclusion lists
EXCLUDE_COMMON=".DS_Store .git .gitignore .gitmodules README.md CLAUDE.md install.sh bootstrap justfile Makefile whitelist.sh docker-compose.yml Dockerfile scripts"
EXCLUDE_LINUX=".yabairc .skhdrc .Brewfile"
EXCLUDE_WSL=".yabairc .skhdrc .Brewfile"

# =============================================================================
# Helper Functions
# =============================================================================

info() {
    echo -e "${BLUE}==>${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            echo "$(uname -m)"
            ;;
    esac
}

get_excludes() {
    case "$PLATFORM" in
        macos) echo "$EXCLUDE_COMMON" ;;
        linux) echo "$EXCLUDE_COMMON $EXCLUDE_LINUX" ;;
        wsl) echo "$EXCLUDE_COMMON $EXCLUDE_WSL" ;;
    esac
}

# =============================================================================
# Installation Functions
# =============================================================================

install_base_tools() {
    info "Installing base tools..."

    case "$PLATFORM" in
        macos)
            if ! command_exists brew; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                # Add Homebrew to PATH for Apple Silicon
                if [[ "$ARCH" == "aarch64" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            else
                success "Homebrew already installed"
            fi
            ;;
        linux|wsl)
            if command_exists apt-get; then
                info "Updating apt packages..."
                sudo apt-get update
                sudo apt-get install -y curl git build-essential zsh
            elif command_exists dnf; then
                info "Updating dnf packages..."
                sudo dnf install -y curl git gcc gcc-c++ make zsh
            elif command_exists pacman; then
                info "Updating pacman packages..."
                sudo pacman -Syu --noconfirm curl git base-devel zsh
            fi
            ;;
    esac
}

install_tools() {
    info "Installing development tools..."

    if [[ -x "$DOTFILES_DIR/scripts/install-tools.sh" ]]; then
        "$DOTFILES_DIR/scripts/install-tools.sh"
    else
        warning "install-tools.sh not found or not executable"
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"

    # If target exists
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        # If it's already the correct symlink, skip
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            success "$target (already linked)"
            return 0
        fi

        # Handle based on interactive mode
        if [[ "$INTERACTIVE" == "false" ]]; then
            # Non-interactive mode: always backup and overwrite
            if [[ ! -L "$target" ]]; then  # Only backup non-symlinks
                backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "$target" "$backup"
                info "Backed up to $backup"
            else
                # Remove existing incorrect symlink
                rm "$target"
            fi
        else
            # Interactive mode: ask for confirmation
            warning "$target already exists"
            read -p "  Overwrite? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                warning "Skipping $target"
                return 0
            fi

            # Backup existing file
            if [[ ! -L "$target" ]]; then  # Only backup non-symlinks
                backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "$target" "$backup"
                info "Backed up to $backup"
            else
                # Remove existing incorrect symlink
                rm "$target"
            fi
        fi
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Create symlink
    ln -s "$source" "$target"
    success "$target"
}

link_dotfiles() {
    info "Creating symlinks for dotfiles..."

    local excludes=$(get_excludes)

    # Link root-level dotfiles
    for file in "$DOTFILES_DIR"/.*; do
        [[ ! -e "$file" ]] && continue

        basename=$(basename "$file")

        # Skip if in exclude list
        if echo " $excludes " | grep -q " $basename "; then
            continue
        fi

        # Skip directories - they are handled separately
        if [[ -d "$file" ]]; then
            case "$basename" in
                ".config"|".claude")
                    # .config and .claude are handled separately
                    continue
                    ;;
                ".zsh")
                    # .zsh directory should be symlinked as a whole
                    ;;
                *)
                    # Skip other directories
                    continue
                    ;;
            esac
        fi

        target="$HOME/$basename"
        create_symlink "$file" "$target"
    done
}

link_config() {
    info "Creating symlinks for .config directory..."

    [[ ! -d "$DOTFILES_DIR/.config" ]] && return 0

    mkdir -p "$HOME/.config"

    for config in "$DOTFILES_DIR/.config"/*; do
        [[ ! -e "$config" ]] && continue

        basename=$(basename "$config")

        # Skip backup files and unwanted directories
        if [[ "$basename" =~ \.backup\. ]] || [[ "$basename" == ".DS_Store" ]]; then
            continue
        fi

        # Platform-specific config exclusions
        case "$PLATFORM" in
            linux|wsl)
                if [[ "$basename" == "posh" ]]; then
                    warning "Skipping $basename (macOS only)"
                    continue
                fi
                ;;
        esac

        target="$HOME/.config/$basename"
        create_symlink "$config" "$target"
    done

    # Link .claude directory
    if [[ -d "$DOTFILES_DIR/.claude" ]]; then
        info "Creating symlinks for .claude directory..."
        mkdir -p "$HOME/.claude"

        # Link directories
        for dir in commands rules agents skills tools; do
            if [[ -d "$DOTFILES_DIR/.claude/$dir" ]]; then
                create_symlink "$DOTFILES_DIR/.claude/$dir" "$HOME/.claude/$dir"
            fi
        done

        # Link files
        for file in CLAUDE.md settings.json; do
            if [[ -f "$DOTFILES_DIR/.claude/$file" ]]; then
                create_symlink "$DOTFILES_DIR/.claude/$file" "$HOME/.claude/$file"
            fi
        done
    fi
}

setup_neovim() {
    info "Setting up Neovim environment..."

    if ! command_exists uv; then
        warning "uv not found, skipping Neovim Python setup"
        return 0
    fi

    # Create venv directory if it doesn't exist
    mkdir -p "$HOME/.venvs"

    # Check if nvim venv already exists
    if [[ -d "$HOME/.venvs/nvim" ]]; then
        info "Neovim venv already exists, updating packages..."
    else
        info "Creating Neovim Python environment..."
        uv venv "$HOME/.venvs/nvim"
    fi

    # Install neovim package
    info "Installing neovim Python package..."
    cd "$HOME/.venvs/nvim"
    uv pip install neovim

    success "Neovim Python environment ready"

    # Install Node.js provider
    if command_exists npm; then
        info "Installing Neovim Node.js provider..."
        npm install -g neovim@latest
        success "Neovim Node.js provider installed"
    fi
}

# =============================================================================
# Main Installation Process
# =============================================================================

show_help() {
    cat <<EOF
Dotfiles Installation Script

Usage:
  $0 [OPTIONS]

Options:
  --help              Show this help message
  --non-interactive   Run in non-interactive mode (auto-accept)

Environment Variables:
  INTERACTIVE=false   Run in non-interactive mode
  DOTFILES_DIR=path   Override dotfiles directory (default: script directory)

Examples:
  $0                           # Interactive installation
  INTERACTIVE=false $0         # Non-interactive installation
  DOTFILES_DIR=~/dotfiles $0   # Use custom directory
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --non-interactive)
                INTERACTIVE=false
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    local start_time=$(date +%s)

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}🚀 Dotfiles Installation${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""

    # Detect platform
    PLATFORM=$(detect_platform)
    ARCH=$(detect_arch)
    info "Platform: $PLATFORM ($ARCH)"
    info "Dotfiles: $DOTFILES_DIR"
    info "Interactive: $INTERACTIVE"

    if [[ "$PLATFORM" == "unknown" ]]; then
        error "Unsupported platform"
        exit 1
    fi

    echo ""

    # Step 1: Install base tools
    info "Step 1/5: Installing base tools..."
    install_base_tools
    echo ""

    # Step 2: Install development tools
    info "Step 2/5: Installing development tools..."
    install_tools
    echo ""

    # Step 3: Create symlinks
    info "Step 3/5: Creating symlinks..."
    link_dotfiles
    echo ""

    # Step 4: Link .config directory
    info "Step 4/5: Linking .config directory..."
    link_config
    echo ""

    # Step 5: Setup Neovim
    info "Step 5/5: Setting up Neovim..."
    setup_neovim
    echo ""

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}✨ Installation Completed!${NC}                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📍 Summary:${NC}"
    echo "  Platform:      $PLATFORM ($ARCH)"
    echo "  Dotfiles Dir:  $DOTFILES_DIR"
    echo "  Duration:      ${duration}s"
    echo ""
    echo -e "${BLUE}📝 Next Steps:${NC}"
    echo "  1. Restart your shell or run:"
    echo -e "     ${YELLOW}source ~/.zshrc${NC}"
    echo ""
    echo "  2. Customize your local settings if needed:"
    echo "     ~/.zshrc_local, ~/.gitconfig_local"
    echo ""

    # Offer to switch to zsh if not already using it
    if [[ "$SHELL" != */zsh ]] && command_exists zsh; then
        echo -e "${YELLOW}💡 Tip: Switch to zsh with:${NC}"
        echo "   chsh -s $(which zsh)"
        echo ""
    fi
}

# Run main function
main "$@"
