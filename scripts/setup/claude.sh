#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLAUDE_DIR="$DOTFILES_DIR/.claude"
source "$DOTFILES_DIR/scripts/lib.sh"

# Directories to link
CLAUDE_DIRS="commands rules agents tools hooks output-styles"

# Files to link
CLAUDE_FILES="CLAUDE.md settings.json statusline.sh"

# ---- Link claude config ----

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

    if [[ -L "$HOME/.claude/docs" ]] && [[ ! -e "$HOME/.claude/docs" ]]; then
        rm "$HOME/.claude/docs"
        info "Removed obsolete symlink $HOME/.claude/docs"
    fi

    # Older setups linked ~/.claude/skills directly into the repo. Skills now
    # live in bigdra50/skills, so the link is dangling — remove it before
    # npx-managed skills write through it into dotfiles.
    if [[ -L "$HOME/.claude/skills" ]] && [[ "$(readlink "$HOME/.claude/skills")" == "$CLAUDE_DIR/skills" ]]; then
        rm "$HOME/.claude/skills"
        info "Removed legacy ~/.claude/skills symlink"
    fi
}

# ---- Install skills ----

install_skills() {
    info "Installing skills via npx skills..."

    if ! command_exists npx; then
        warning "npx not found, skipping skills installation"
        return
    fi

    npx skills add "github:bigdra50/skills" -g -y
    npx skills add "github:bigdra50/unity-cli" -g -y
}

# ---- Main ----

link_claude
install_skills

# Sync rules to Codex/Copilot
info "Syncing rules to Codex/Copilot..."
bash "$DOTFILES_DIR/scripts/sync-rules.sh" --global

success "Claude Code configuration installed"
