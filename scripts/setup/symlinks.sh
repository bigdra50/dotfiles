#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$DOTFILES_DIR/scripts/lib.sh"

PLATFORM=$(detect_platform)

# File exclusion lists
EXCLUDE_COMMON=".DS_Store .git .gitignore .gitmodules README.md CLAUDE.md install.sh install.ps1 bootstrap bootstrap.ps1 docker-compose.yml Dockerfile scripts mise.toml"
EXCLUDE_LINUX=".yabairc .skhdrc"
EXCLUDE_WSL=".yabairc .skhdrc"

get_excludes() {
    case "$PLATFORM" in
        macos) echo "$EXCLUDE_COMMON" ;;
        linux) echo "$EXCLUDE_COMMON $EXCLUDE_LINUX" ;;
        wsl) echo "$EXCLUDE_COMMON $EXCLUDE_WSL" ;;
    esac
}

# ---- Root-level dotfiles ----

link_dotfiles() {
    info "Creating symlinks for dotfiles..."
    local excludes=$(get_excludes)

    for file in "$DOTFILES_DIR"/.*; do
        [[ ! -e "$file" ]] && continue
        local basename=$(basename "$file")

        if echo " $excludes " | grep -q " $basename "; then
            continue
        fi

        if [[ -d "$file" ]]; then
            case "$basename" in
                ".config"|".claude") continue ;;
                ".zsh") ;;
                *) continue ;;
            esac
        fi

        create_symlink "$file" "$HOME/$basename"
    done
}

# ---- .config directory ----

link_config() {
    info "Creating symlinks for .config directory..."
    [[ ! -d "$DOTFILES_DIR/.config" ]] && return 0

    mkdir -p "$HOME/.config"

    for config in "$DOTFILES_DIR/.config"/*; do
        [[ ! -e "$config" ]] && continue
        local basename=$(basename "$config")

        if [[ "$basename" =~ \.backup\. ]] || [[ "$basename" == ".DS_Store" ]]; then
            continue
        fi

        case "$PLATFORM" in
            linux|wsl)
                if [[ "$basename" == "posh" || "$basename" == "yashiki" ]]; then
                    warning "Skipping $basename (macOS only)"
                    continue
                fi
                ;;
        esac

        create_symlink "$config" "$HOME/.config/$basename"
    done
}

# ---- Main ----

link_dotfiles
link_config

success "Symlinks created"
