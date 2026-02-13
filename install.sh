#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installation Script
# =============================================================================
# Usage:
#   ./install.sh                              # Interactive, all steps
#   INTERACTIVE=false ./install.sh            # Non-interactive, all steps
#   ./install.sh --only symlinks              # Symlinks only
#   ./install.sh --only symlinks,config       # Multiple steps
#   ./install.sh --help                       # Show help

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
INTERACTIVE="${INTERACTIVE:-true}"
STEPS="base,tools,symlinks,config,neovim"

# Source shared library
source "$SCRIPT_DIR/scripts/lib.sh"

# File exclusion lists
EXCLUDE_COMMON=".DS_Store .git .gitignore .gitmodules README.md CLAUDE.md install.sh bootstrap docker-compose.yml Dockerfile scripts"
EXCLUDE_LINUX=".yabairc .skhdrc"
EXCLUDE_WSL=".yabairc .skhdrc"

# =============================================================================
# Step Control
# =============================================================================

should_run_step() {
    [[ ",$STEPS," == *",$1,"* ]]
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
                sudo dnf install -y curl git gcc gcc-c++ make zsh
            elif command_exists pacman; then
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

trust_mise_configs() {
    if command_exists mise; then
        info "Trusting mise configuration files..."
        mise trust "$DOTFILES_DIR/.mise.toml" 2>/dev/null || true
        mise trust "$DOTFILES_DIR/.config/mise/config.toml" 2>/dev/null || true
    fi
}

link_dotfiles() {
    info "Creating symlinks for dotfiles..."

    local excludes=$(get_excludes)

    for file in "$DOTFILES_DIR"/.*; do
        [[ ! -e "$file" ]] && continue

        basename=$(basename "$file")

        if echo " $excludes " | grep -q " $basename "; then
            continue
        fi

        if [[ -d "$file" ]]; then
            case "$basename" in
                ".config"|".claude")
                    continue
                    ;;
                ".zsh")
                    ;;
                *)
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

        if [[ "$basename" =~ \.backup\. ]] || [[ "$basename" == ".DS_Store" ]]; then
            continue
        fi

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
    if [[ -x "$DOTFILES_DIR/.claude/install.sh" ]]; then
        CLAUDE_DIR="$DOTFILES_DIR/.claude" INTERACTIVE="$INTERACTIVE" "$DOTFILES_DIR/.claude/install.sh"
    elif [[ -d "$DOTFILES_DIR/.claude" ]]; then
        warning ".claude/install.sh not found or not executable, skipping Claude configuration"
    fi
}

setup_neovim() {
    info "Setting up Neovim environment..."

    if ! command_exists uv; then
        warning "uv not found, skipping Neovim Python setup"
        return 0
    fi

    mkdir -p "$HOME/.venvs"

    if [[ -d "$HOME/.venvs/nvim" ]]; then
        info "Neovim venv already exists, updating packages..."
    else
        info "Creating Neovim Python environment..."
        uv venv "$HOME/.venvs/nvim"
    fi

    info "Installing neovim Python package..."
    cd "$HOME/.venvs/nvim"
    uv pip install neovim

    success "Neovim Python environment ready"

    if command_exists npm; then
        info "Installing Neovim Node.js provider..."
        npm install -g neovim@latest
        success "Neovim Node.js provider installed"
    fi
}

# =============================================================================
# Main
# =============================================================================

show_help() {
    cat <<EOF
Dotfiles Installation Script

Usage:
  $0 [OPTIONS]

Options:
  --help              Show this help message
  --non-interactive   Run in non-interactive mode (auto-accept)
  --only STEPS        Run only specific steps (comma-separated)
                      Available: base, tools, symlinks, config, neovim
                      Default: all steps

Examples:
  $0                              # Full interactive installation
  $0 --only symlinks              # Only create symlinks
  $0 --only symlinks,config       # Symlinks and .config
  INTERACTIVE=false $0            # Non-interactive full installation
  INTERACTIVE=false $0 --only tools   # Non-interactive tool install
EOF
}

main() {
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
            --only)
                STEPS="$2"
                shift 2
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Validate steps
    IFS=',' read -ra STEP_ARRAY <<< "$STEPS"
    for step in "${STEP_ARRAY[@]}"; do
        if [[ ! "$step" =~ ^(base|tools|symlinks|config|neovim)$ ]]; then
            error "Invalid step: $step"
            echo "Valid steps: base, tools, symlinks, config, neovim"
            exit 1
        fi
    done

    local start_time=$(date +%s)

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}Dotfiles Installation${NC}                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""

    PLATFORM=$(detect_platform)
    ARCH=$(detect_arch)
    info "Platform: $PLATFORM ($ARCH)"
    info "Dotfiles: $DOTFILES_DIR"
    info "Interactive: $INTERACTIVE"
    info "Steps: $STEPS"

    if [[ "$PLATFORM" == "unknown" ]]; then
        error "Unsupported platform"
        exit 1
    fi

    echo ""

    if should_run_step "base"; then
        info "Step [base]: Installing base tools..."
        install_base_tools
        echo ""
    fi

    # Trust mise configs early to avoid warnings on shell startup
    trust_mise_configs

    if should_run_step "tools"; then
        info "Step [tools]: Installing development tools..."
        install_tools
        echo ""
    fi

    if should_run_step "symlinks"; then
        info "Step [symlinks]: Creating symlinks..."
        link_dotfiles
        echo ""
    fi

    if should_run_step "config"; then
        info "Step [config]: Linking .config directory..."
        link_config
        echo ""
    fi

    if should_run_step "neovim"; then
        info "Step [neovim]: Setting up Neovim..."
        setup_neovim
        echo ""
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}Installation Completed${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Platform:      $PLATFORM ($ARCH)"
    echo "  Dotfiles Dir:  $DOTFILES_DIR"
    echo "  Steps:         $STEPS"
    echo "  Duration:      ${duration}s"
    echo ""
    echo "  Next steps:"
    echo "    1. Restart your shell or: source ~/.zshrc"
    echo "    2. Customize: ~/.zshrc_local, ~/.gitconfig_local"
    echo ""

    if [[ "$SHELL" != */zsh ]] && command_exists zsh; then
        echo "  Switch to zsh: chsh -s $(which zsh)"
        echo ""
    fi
}

main "$@"
