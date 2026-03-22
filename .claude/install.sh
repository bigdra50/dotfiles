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
CLAUDE_DIRS="commands rules agents tools hooks output-styles"

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

install_skills() {
    info "Installing skills..."
    mkdir -p "$HOME/.claude/skills"

    # Self-managed skills: symlink directly from dotfiles (edits reflected immediately)
    if [[ -d "$CLAUDE_DIR/skills" ]]; then
        for skill_dir in "$CLAUDE_DIR/skills"/*/; do
            [[ ! -d "$skill_dir" ]] && continue
            [[ ! -f "$skill_dir/SKILL.md" ]] && continue
            local name
            name=$(basename "$skill_dir")
            create_symlink "$skill_dir" "$HOME/.claude/skills/$name"
        done
    fi

    # External skills: install via npx skills
    if command -v npx &>/dev/null; then
        npx skills add "github:bigdra50/unity-cli" -g -y
    else
        warning "npx not found, skipping external skills installation"
    fi
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
    install_skills

    echo ""
    success "Claude Code configuration installed!"
}

main "$@"
