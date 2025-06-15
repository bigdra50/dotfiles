#!/usr/bin/env just --justfile
# =====================================================
# Dotfiles Management with Just
# =====================================================

# Show available commands by default
default:
    @just --list --unsorted

# =====================================================
# Configuration Variables
# =====================================================

# Repository configuration
export REPO_URL := "https://github.com/bigdra50/dotfiles.git"
export DOTFILES_DIR := env_var_or_default("DOTFILES_DIR", "$HOME/dev/github.com/bigdra50/dotfiles")

# Interactive mode flag (set to "false" for non-interactive)
export INTERACTIVE := env_var_or_default("INTERACTIVE", "true")

# Platform detection
export OS := os()
export ARCH := arch()
export IS_WSL := if os() == "linux" { `if grep -qi microsoft /proc/version 2>/dev/null; then echo "true"; else echo "false"; fi` } else { "false" }
export PLATFORM := if os() == "macos" { "macos" } else if IS_WSL == "true" { "wsl" } else if os() == "linux" { "linux" } else { "unknown" }

# File exclusion lists
export EXCLUDE_COMMON := ".DS_Store .git .gitignore README.md CLAUDE.md install.sh justfile Makefile whitelist.sh docker-compose.yml Dockerfile"
export EXCLUDE_LINUX := ".yabairc .skhdrc .Brewfile"
export EXCLUDE_WSL := ".yabairc .skhdrc .Brewfile"

# Color output
export RED := '\033[0;31m'
export GREEN := '\033[0;32m'
export YELLOW := '\033[1;33m'
export BLUE := '\033[0;34m'
export NC := '\033[0m'

# =====================================================
# Main Commands
# =====================================================

# 🚀 Initialize dotfiles for the current platform
init: check-platform
    @echo -e "${GREEN}🚀 Initializing dotfiles for ${PLATFORM}...${NC}"
    @just clone
    @just install-tools
    @just link
    @echo -e "${GREEN}✅ Dotfiles initialization completed!${NC}"
    @echo -e "${YELLOW}🔄 Please restart your shell or run: source ~/.zshrc${NC}"

# 📦 Clone or update dotfiles repository
clone:
    #!/usr/bin/env bash
    set -euo pipefail
    
    if [[ -d "{{ DOTFILES_DIR }}" ]]; then
        echo -e "${BLUE}📂 Dotfiles directory already exists${NC}"
        
        # Fix git remote for Docker environments
        cd "{{ DOTFILES_DIR }}"
        current_remote=$(git remote get-url origin 2>/dev/null || echo "")
        if [[ "$current_remote" =~ ^git@github.com ]]; then
            echo -e "${YELLOW}🔧 Switching to HTTPS remote for Docker compatibility...${NC}"
            git remote set-url origin "{{ REPO_URL }}"
        fi
        
        echo -e "${YELLOW}⬇️  Pulling latest changes...${NC}"
        git pull
    else
        echo -e "${BLUE}📥 Cloning dotfiles repository...${NC}"
        mkdir -p "$(dirname {{ DOTFILES_DIR }})"
        git clone "{{ REPO_URL }}" "{{ DOTFILES_DIR }}"
    fi

# 🔗 Create symlinks for all dotfiles
link: check-platform
    @echo -e "${BLUE}🔗 Creating symlinks for ${PLATFORM}...${NC}"
    @just _link-files
    @just _link-config

# 🛠️  Install platform-specific tools
install-tools: check-platform
    @echo -e "${BLUE}🛠️  Installing tools for ${PLATFORM}...${NC}"
    @just _install-base-tools
    @just _install-platform-tools
    @just _install-common-tools
    @just setup-nvim

# 🗑️  Remove all symlinks
unlink:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo -e "${YELLOW}🗑️  Removing symlinks...${NC}"
    for link in $(find "$HOME" -maxdepth 1 -type l); do
        if [[ "$(readlink "$link")" =~ {{ DOTFILES_DIR }} ]]; then
            echo "Removing: $link"
            rm "$link"
        fi
    done
    
    # Remove .config symlinks
    if [[ -d "$HOME/.config" ]]; then
        for link in $(find "$HOME/.config" -maxdepth 1 -type l); do
            if [[ "$(readlink "$link")" =~ {{ DOTFILES_DIR }} ]]; then
                echo "Removing: $link"
                rm "$link"
            fi
        done
    fi

# 🔍 Show platform information
info:
    @echo -e "${BLUE}System Information:${NC}"
    @echo "  OS:       {{ OS }}"
    @echo "  Arch:     {{ ARCH }}"
    @echo "  WSL:      {{ IS_WSL }}"
    @echo "  Platform: {{ PLATFORM }}"
    @echo ""
    @echo -e "${BLUE}Dotfiles Configuration:${NC}"
    @echo "  Directory: {{ DOTFILES_DIR }}"
    @echo "  Excludes:  $(just _get-excludes)"

# =====================================================
# Platform-specific Tool Installation
# =====================================================

# Install base tools based on platform
_install-base-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    
    case "{{ PLATFORM }}" in
        macos)
            if ! command -v brew &>/dev/null; then
                echo -e "${YELLOW}📦 Installing Homebrew...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add Homebrew to PATH for Apple Silicon
                if [[ "{{ ARCH }}" == "aarch64" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                fi
            fi
            ;;
        linux|wsl)
            # Update package manager
            if command -v apt &>/dev/null; then
                echo -e "${YELLOW}📦 Updating apt packages...${NC}"
                sudo apt update
                sudo apt install -y curl git build-essential zsh
            elif command -v dnf &>/dev/null; then
                echo -e "${YELLOW}📦 Updating dnf packages...${NC}"
                sudo dnf install -y curl git gcc gcc-c++ make zsh
            elif command -v pacman &>/dev/null; then
                echo -e "${YELLOW}📦 Updating pacman packages...${NC}"
                sudo pacman -Syu --noconfirm curl git base-devel zsh
            fi
            ;;
    esac

# Install platform-specific tools
_install-platform-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    
    case "{{ PLATFORM }}" in
        macos)
            if [[ -f "{{ DOTFILES_DIR }}/.Brewfile" ]]; then
                echo -e "${YELLOW}📦 Installing from Brewfile...${NC}"
                # Check if packages need to be installed
                if ! brew bundle check --file="{{ DOTFILES_DIR }}/.Brewfile" &>/dev/null; then
                    brew bundle --file="{{ DOTFILES_DIR }}/.Brewfile"
                else
                    echo -e "${GREEN}✓${NC} Brew packages already up to date"
                fi
            fi
            ;;
        linux|wsl)
            # Install Linux-specific tools
            if command -v apt &>/dev/null; then
                # Check if packages are already installed
                packages=()
                for pkg in fd-find bat; do
                    if ! dpkg -l "$pkg" &>/dev/null; then
                        packages+=("$pkg")
                    fi
                done
                
                if [[ ${#packages[@]} -gt 0 ]]; then
                    echo -e "${YELLOW}📦 Installing Linux packages: ${packages[*]}${NC}"
                    sudo apt install -y "${packages[@]}"
                else
                    echo -e "${GREEN}✓${NC} Linux packages already installed"
                fi
            fi
            ;;
    esac

# Install common development tools
_install-common-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Use the unified tool installation script
    echo -e "${YELLOW}📦 Installing tools from tools.toml...${NC}"
    
    if [[ -x "{{ DOTFILES_DIR }}/scripts/install-tools.sh" ]]; then
        "{{ DOTFILES_DIR }}/scripts/install-tools.sh"
    else
        # Fallback to inline installation if script doesn't exist
        warning "install-tools.sh not found, using fallback installation"
        
        # Install mise
        if ! command -v mise &>/dev/null; then
            echo -e "${YELLOW}📦 Installing mise...${NC}"
            curl https://mise.run | sh
            export PATH="$HOME/.local/bin:$PATH"
        fi
        
        # Basic tool installation
        if command -v mise &>/dev/null; then
            mise use --global rust@latest
            mise use --global go@latest
            mise use --global node@latest
        fi
    fi

# =====================================================
# Internal Helper Commands
# =====================================================

# Check platform support
check-platform:
    #!/usr/bin/env bash
    if [[ "{{ PLATFORM }}" == "unknown" ]]; then
        echo -e "${RED}❌ Error: Unsupported platform${NC}"
        exit 1
    fi

# Get platform-specific excludes
_get-excludes:
    #!/usr/bin/env bash
    case "{{ PLATFORM }}" in
        macos) echo "{{ EXCLUDE_COMMON }}" ;;
        linux) echo "{{ EXCLUDE_COMMON }} {{ EXCLUDE_LINUX }}" ;;
        wsl) echo "{{ EXCLUDE_COMMON }} {{ EXCLUDE_WSL }}" ;;
    esac

# Create symlinks for dotfiles
_link-files:
    #!/usr/bin/env bash
    set -euo pipefail
    
    EXCLUDES=$(just _get-excludes)
    
    # Link root-level dotfiles
    for file in {{ DOTFILES_DIR }}/.*; do
        [[ ! -e "$file" ]] && continue
        
        basename=$(basename "$file")
        
        # Skip if in exclude list
        if echo " $EXCLUDES " | grep -q " $basename "; then
            continue
        fi
        
        # Skip directories - they are handled separately
        if [[ -d "$file" ]]; then
            case "$basename" in
                ".config")
                    # .config is handled by _link-config recipe
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
        just _create-symlink "$file" "$target"
    done

# Create symlinks for .config directory
_link-config:
    #!/usr/bin/env bash
    set -euo pipefail
    
    [[ ! -d "{{ DOTFILES_DIR }}/.config" ]] && exit 0
    
    mkdir -p "$HOME/.config"
    EXCLUDES=$(just _get-excludes)
    
    for config in {{ DOTFILES_DIR }}/.config/*; do
        [[ ! -e "$config" ]] && continue
        
        basename=$(basename "$config")
        
        # Skip backup files and unwanted directories
        if [[ "$basename" =~ \.backup\. ]] || [[ "$basename" == ".android" ]] || [[ "$basename" == ".mono" ]] || [[ "$basename" == ".DS_Store" ]]; then
            continue
        fi
        
        # Platform-specific config exclusions
        case "{{ PLATFORM }}" in
            linux|wsl)
                if [[ "$basename" == "posh" ]]; then
                    echo -e "${YELLOW}⏭️  Skipping $basename (macOS only)${NC}"
                    continue
                fi
                ;;
        esac
        
        target="$HOME/.config/$basename"
        just _create-symlink "$config" "$target"
    done

# Create a single symlink with confirmation
_create-symlink source target:
    #!/usr/bin/env bash
    set -euo pipefail
    
    # If target exists
    if [[ -e "{{ target }}" ]] || [[ -L "{{ target }}" ]]; then
        # If it's already the correct symlink, skip
        if [[ -L "{{ target }}" ]] && [[ "$(readlink "{{ target }}")" == "{{ source }}" ]]; then
            echo -e "${GREEN}✓${NC} {{ target }} (already linked)"
            exit 0
        fi
        
        # Handle based on interactive mode
        if [[ "${INTERACTIVE:-true}" == "false" ]]; then
            # Non-interactive mode: always backup and overwrite
            if [[ ! -L "{{ target }}" ]]; then  # Only backup non-symlinks
                backup="{{ target }}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "{{ target }}" "$backup"
                echo -e "${BLUE}📋 Backed up to $backup${NC}"
            else
                # Remove existing incorrect symlink
                rm "{{ target }}"
            fi
        else
            # Interactive mode: ask for confirmation
            echo -e "${YELLOW}⚠️  {{ target }} already exists${NC}"
            read -p "  Overwrite? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}⏭️  Skipping {{ target }}${NC}"
                exit 0
            fi
            
            # Backup existing file
            if [[ ! -L "{{ target }}" ]]; then  # Only backup non-symlinks
                backup="{{ target }}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "{{ target }}" "$backup"
                echo -e "${BLUE}📋 Backed up to $backup${NC}"
            else
                # Remove existing incorrect symlink
                rm "{{ target }}"
            fi
        fi
    fi
    
    # Create parent directory if needed
    mkdir -p "$(dirname "{{ target }}")"
    
    # Create symlink
    ln -s "{{ source }}" "{{ target }}"
    echo -e "${GREEN}✓${NC} {{ target }}"

# =====================================================
# Neovim Setup
# =====================================================

# 🔧 Setup Neovim Python environment
setup-nvim:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo -e "${BLUE}🔧 Setting up Neovim Python environment...${NC}"
    
    # Create venv directory if it doesn't exist
    mkdir -p "$HOME/.venvs"
    
    # Check if nvim venv already exists
    if [[ -d "$HOME/.venvs/nvim" ]]; then
        echo -e "${YELLOW}📂 Neovim venv already exists, updating packages...${NC}"
    else
        echo -e "${GREEN}🐍 Creating Neovim Python environment...${NC}"
        uv venv "$HOME/.venvs/nvim"
    fi
    
    # Install neovim package
    echo -e "${YELLOW}📦 Installing neovim Python package...${NC}"
    cd "$HOME/.venvs/nvim"
    uv pip install neovim
    
    echo -e "${GREEN}✅ Neovim Python environment ready${NC}"
    
    # Install Node.js provider
    echo -e "${YELLOW}📦 Installing Neovim Node.js provider...${NC}"
    if command -v npm &>/dev/null; then
        npm install -g neovim@latest
        echo -e "${GREEN}✅ Neovim Node.js provider installed${NC}"
    else
        echo -e "${RED}❌ npm not found. Node.js provider not installed${NC}"
    fi

# =====================================================
# Development and Testing Commands
# =====================================================

# 🐳 Build Docker images for testing
docker-build:
    @echo -e "${BLUE}🔨 Building Docker image for Ubuntu 24.04...${NC}"
    docker-compose build ubuntu-dotfiles

# 🐳 Build all Docker test images
docker-build-all:
    @echo -e "${BLUE}🔨 Building all Docker test images...${NC}"
    docker-compose build

# 🐳 Run dotfiles initialization in Ubuntu container
docker-test:
    @echo -e "${BLUE}🧪 Testing dotfiles installation in Ubuntu 24.04...${NC}"
    docker-compose run --rm ubuntu-dotfiles bash -c "cd ~/.ghq/github.com/bigdra50/dotfiles && just init"

# 🐳 Run dotfiles initialization in Ubuntu 22.04 container
docker-test-22:
    @echo -e "${BLUE}🧪 Testing dotfiles installation in Ubuntu 22.04...${NC}"
    docker-compose run --rm ubuntu-22-dotfiles bash -c "cd ~/.ghq/github.com/bigdra50/dotfiles && just init"

# 🐳 Enter Ubuntu container shell
docker-shell:
    @echo -e "${BLUE}🔍 Entering Ubuntu 24.04 container...${NC}"
    docker-compose run --rm ubuntu-dotfiles

# 🐳 Enter Ubuntu 22.04 container shell
docker-shell-22:
    @echo -e "${BLUE}🔍 Entering Ubuntu 22.04 container...${NC}"
    docker-compose run --rm ubuntu-22-dotfiles

# 🐳 Run specific command in container
docker-run cmd:
    docker-compose run --rm ubuntu-dotfiles bash -c "{{ cmd }}"

# 🐳 Clean up Docker resources
docker-clean:
    @echo -e "${YELLOW}🧹 Cleaning up Docker resources...${NC}"
    docker-compose down -v
    docker rmi dotfiles-ubuntu:latest dotfiles-ubuntu22:latest 2>/dev/null || true

# 🐳 View container logs
docker-logs:
    docker-compose logs -f

# 🧪 Test specific platform in Docker
test-platform platform="wsl":
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo -e "${BLUE}🧪 Testing platform simulation: {{ platform }}${NC}"
    
    # Build and run with platform override
    docker-compose run --rm \
        -e "FORCE_PLATFORM={{ platform }}" \
        ubuntu-dotfiles bash -c "cd ~/.ghq/github.com/bigdra50/dotfiles && just info && just init"

# 🧪 Validate justfile syntax
validate:
    @just --fmt --check --unstable

# 📝 Format justfile
fmt:
    @just --fmt --unstable