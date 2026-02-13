#!/usr/bin/env bash
# =============================================================================
# Claude Code Configuration Installation Script
# =============================================================================
# Usage:
#   ./.claude/install.sh                    # Interactive installation
#   INTERACTIVE=false ./.claude/install.sh  # Non-interactive installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$SCRIPT_DIR}"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"
INTERACTIVE="${INTERACTIVE:-true}"

# Source shared library
source "$DOTFILES_DIR/scripts/lib.sh"

# Directories to link
CLAUDE_DIRS="commands rules agents skills tools hooks output-styles"

# Files to link
CLAUDE_FILES="CLAUDE.md settings.json statusline.sh"

# =============================================================================
# Installation
# =============================================================================

link_claude() {
    info "Creating symlinks for .claude directory..."

    if [[ ! -d "$CLAUDE_DIR" ]]; then
        error "Claude directory not found: $CLAUDE_DIR"
        return 1
    fi

    mkdir -p "$HOME/.claude"

    for dir in $CLAUDE_DIRS; do
        if [[ -d "$CLAUDE_DIR/$dir" ]]; then
            create_symlink "$CLAUDE_DIR/$dir" "$HOME/.claude/$dir"
        fi
    done

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
    echo ""

    link_claude

    echo ""
    success "Claude Code configuration installed!"
}

main "$@"
