#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLAUDE_DIR="$DOTFILES_DIR/.claude"
source "$DOTFILES_DIR/scripts/lib.sh"

# Directories to link
# NOTE: agents are no longer symlinked — they are apm-managed primitives
# (source: .apm/agents/*.agent.md) deployed to ~/.claude/agents by install_skills.
CLAUDE_DIRS="commands rules tools hooks output-styles scripts"

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
    # live in bigdra50/skills and are deployed by apm, so the link is dangling —
    # remove it before apm writes skill folders through it into dotfiles.
    # NOTE: compare by dangling-ness, not readlink string equality — the repo
    # may be reached via an alias path (e.g. ~/dotfiles -> ~/dev/.../dotfiles
    # under ghq), which makes readlink's literal target differ from $CLAUDE_DIR
    # even though both resolve to the same file.
    if [[ -L "$HOME/.claude/skills" ]] && [[ ! -e "$HOME/.claude/skills" ]]; then
        rm "$HOME/.claude/skills"
        info "Removed legacy ~/.claude/skills symlink"
    fi

    # Agents used to be symlinked from .claude/agents; they are now apm-managed
    # primitives (.apm/agents/*.agent.md) deployed by apm. .claude/agents no
    # longer exists in the repo, so the legacy symlink is always dangling now.
    # Remove it so apm writes real agent files into ~/.claude/agents.
    if [[ -L "$HOME/.claude/agents" ]] && [[ ! -e "$HOME/.claude/agents" ]]; then
        rm "$HOME/.claude/agents"
        info "Removed legacy ~/.claude/agents symlink (now apm-managed)"
    fi
}

# ---- Apply settings.json (merge, not symlink) ----

# Claude Code rewrites settings.json atomically at runtime (tmp file + rename),
# which replaces a symlink with a real file and lets it drift from dotfiles.
# Instead, deep-merge the dotfiles version onto the live file (merge_json_onto).
# Keys absent from dotfiles keep their live value, so a per-machine choice
# (for example the effort level) survives setup as long as dotfiles omits it.
apply_claude_settings() {
    merge_json_onto "$CLAUDE_DIR/settings.json" "$HOME/.claude/settings.json"
}

# ---- Install skills (via apm) ----

# 実装は scripts/setup/skills.sh。chezmoi の run_onchange スクリプトも同じものを呼ぶ。
# 失敗しても setup の残り (rules の同期) は続ける。
install_skills() {
    if ! bash "$DOTFILES_DIR/scripts/setup/skills.sh"; then
        warning "Skills were not installed; fix the cause and run 'mise run setup:claude' again"
    fi
}

# ---- Install textlint (Markdown の文体検査) ----

# 実装は scripts/setup/textlint.sh。chezmoi の run_onchange スクリプトも同じものを呼ぶ。
ensure_textlint() {
    bash "$DOTFILES_DIR/scripts/setup/textlint.sh"
}

# ---- Main ----

link_claude
apply_claude_settings
ensure_textlint
install_skills

# Sync rules to Codex/Copilot
info "Syncing rules to Codex/Copilot..."
bash "$DOTFILES_DIR/scripts/sync-rules.sh" --global

success "Claude Code configuration installed"
