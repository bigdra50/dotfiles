#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLAUDE_DIR="$DOTFILES_DIR/.claude"
source "$DOTFILES_DIR/scripts/lib.sh"

# Directories to link
CLAUDE_DIRS="commands rules agents tools hooks output-styles scripts"

# Files to link
# NOTE: settings.json は symlink しない。Claude Code が実行時に atomic write
# (tmp file + rename) で保存するため symlink が実ファイルに置換されて乖離する。
# 代わりに apply_claude_settings で jq マージ適用する。
CLAUDE_FILES="CLAUDE.md statusline.sh"

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

# ---- Apply settings.json (merge, not symlink) ----

# Claude Code rewrites settings.json atomically at runtime (tmp file + rename),
# which replaces a symlink with a real file and lets it drift from dotfiles.
# Instead, deep-merge the dotfiles version onto the live file:
#   - keys defined in dotfiles win (desired state)
#   - runtime-only keys in the live file are preserved
apply_claude_settings() {
    local source="$CLAUDE_DIR/settings.json"
    local target="$HOME/.claude/settings.json"

    if ! command_exists jq; then
        warning "jq not found; skipping settings.json apply"
        return 0
    fi

    if ! jq empty "$source" 2>/dev/null; then
        error "Invalid JSON in $source; not applying"
        return 1
    fi

    # Legacy: target may still be a symlink into the repo — materialize it
    if [[ -L "$target" ]]; then
        rm "$target"
    fi

    if [[ ! -f "$target" ]]; then
        install -m 600 "$source" "$target"
        success "$target (created from dotfiles)"
        return 0
    fi

    if ! jq empty "$target" 2>/dev/null; then
        error "Invalid JSON in $target; fix it before applying settings"
        return 1
    fi

    local merged
    merged="$(jq -s '.[0] * .[1]' "$target" "$source")" || return 1

    if [[ "$(printf '%s' "$merged" | jq -S .)" == "$(jq -S . "$target")" ]]; then
        success "$target (settings already up to date)"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"
    printf '%s\n' "$merged" >"$tmp"
    chmod 600 "$tmp"
    mv "$tmp" "$target"
    success "$target (merged dotfiles settings)"
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
apply_claude_settings
install_skills

# Sync rules to Codex/Copilot
info "Syncing rules to Codex/Copilot..."
bash "$DOTFILES_DIR/scripts/sync-rules.sh" --global

success "Claude Code configuration installed"
