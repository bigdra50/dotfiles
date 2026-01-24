#!/usr/bin/env bash
# =============================================================================
# Claude Code Configuration Installation Script
# =============================================================================
# This script installs Claude Code configuration files
#
# Usage:
#   ./.claude/install.sh                    # Interactive installation
#   INTERACTIVE=false ./.claude/install.sh  # Non-interactive installation

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$SCRIPT_DIR}"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"

# Interactive mode flag
INTERACTIVE="${INTERACTIVE:-true}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Directories to link
CLAUDE_DIRS="commands rules agents skills tools hooks output-styles"

# Files to link
CLAUDE_FILES="CLAUDE.md settings.json statusline.sh"

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

# =============================================================================
# Installation Functions
# =============================================================================

link_claude() {
    info "Creating symlinks for .claude directory..."

    if [[ ! -d "$CLAUDE_DIR" ]]; then
        error "Claude directory not found: $CLAUDE_DIR"
        return 1
    fi

    mkdir -p "$HOME/.claude"

    # Link directories
    for dir in $CLAUDE_DIRS; do
        if [[ -d "$CLAUDE_DIR/$dir" ]]; then
            create_symlink "$CLAUDE_DIR/$dir" "$HOME/.claude/$dir"
        fi
    done

    # Link files
    for file in $CLAUDE_FILES; do
        if [[ -f "$CLAUDE_DIR/$file" ]]; then
            create_symlink "$CLAUDE_DIR/$file" "$HOME/.claude/$file"
        fi
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    info "Claude Code Configuration Installer"
    info "Source: $CLAUDE_DIR"
    info "Target: $HOME/.claude"
    info "Interactive: $INTERACTIVE"
    echo ""

    link_claude

    echo ""
    success "Claude Code configuration installed!"
}

main "$@"
