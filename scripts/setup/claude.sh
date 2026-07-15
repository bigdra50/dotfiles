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
    if [[ -L "$HOME/.claude/skills" ]] && [[ "$(readlink "$HOME/.claude/skills")" == "$CLAUDE_DIR/skills" ]]; then
        rm "$HOME/.claude/skills"
        info "Removed legacy ~/.claude/skills symlink"
    fi

    # Agents used to be symlinked from .claude/agents; they are now apm-managed
    # primitives (.apm/agents/*.agent.md) deployed by apm. Remove the legacy
    # symlink so apm writes real agent files into ~/.claude/agents.
    if [[ -L "$HOME/.claude/agents" ]] && [[ "$(readlink "$HOME/.claude/agents")" == "$CLAUDE_DIR/agents" ]]; then
        rm "$HOME/.claude/agents"
        info "Removed legacy ~/.claude/agents symlink (now apm-managed)"
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

# ---- Install skills (via apm) ----

# apm CLI のバージョン (release tarball を固定取得する)
APM_VERSION="0.24.1"

# apm (Microsoft Agent Package Manager) を sudo 無しで ~/.local に導入する。
# 公式インストーラ (curl https://aka.ms/apm-unix | sh) は /usr/local/bin へ sudo
# 導入するため、非対話・パスワード無しの環境で失敗する。ここでは release tarball を
# ~/.local/share/apm へ展開し ~/.local/bin/apm に symlink する。apm は PyInstaller
# onedir バンドルなので、単体バイナリではなく _internal/ ごと配置する必要がある。
ensure_apm() {
    if command_exists apm; then
        success "apm already installed ($(apm --version 2>/dev/null | head -1))"
        return 0
    fi

    local arch os tarball url tmp extracted
    case "$(uname -m)" in
        x86_64 | amd64) arch="x86_64" ;;
        aarch64 | arm64) arch="aarch64" ;;
        *)
            warning "Unsupported arch for apm ($(uname -m)); skipping skills"
            return 1
            ;;
    esac
    case "$(uname -s)" in
        Darwin*) os="macos" ;;
        Linux*) os="linux" ;;
        *)
            warning "Unsupported OS for apm; skipping skills"
            return 1
            ;;
    esac
    tarball="apm-${os}-${arch}.tar.gz"
    url="https://github.com/microsoft/apm/releases/download/v${APM_VERSION}/${tarball}"

    info "Installing apm ${APM_VERSION} to ~/.local (sudo-free)..."
    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/apm.tar.gz" "$url"; then
        warning "Failed to download apm; skipping skills"
        rm -rf "$tmp"
        return 1
    fi
    tar xzf "$tmp/apm.tar.gz" -C "$tmp"
    extracted="$(find "$tmp" -maxdepth 1 -type d -name 'apm-*' | head -1)"
    if [[ -z "$extracted" ]]; then
        warning "Unexpected apm archive layout; skipping skills"
        rm -rf "$tmp"
        return 1
    fi
    mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
    rm -rf "$HOME/.local/share/apm"
    mv "$extracted" "$HOME/.local/share/apm"
    ln -sf "$HOME/.local/share/apm/apm" "$HOME/.local/bin/apm"
    rm -rf "$tmp"
    export PATH="$HOME/.local/bin:$PATH"
    command_exists apm && success "apm installed ($(apm --version 2>/dev/null | head -1))"
}

# 旧 skillpm (`npx skills add`) が残した収束レイアウトを撤去する。
# skillpm は実体を ~/.agents/skills に置き ~/.claude/skills/<name> をそこへ symlink
# する。apm は実体を ~/.claude/skills に直接配置するため、両者が衝突しないよう
# skillpm 状態を検出したらバックアップして退避する (apm 管理下では no-op)。
cleanup_legacy_skillpm() {
    local skills_dir="$HOME/.claude/skills"
    [[ -f "$HOME/.agents/.skill-lock.json" ]] || return 0

    local ts backup
    ts="$(date +%Y%m%d_%H%M%S)"
    backup="$HOME/.claude/skills.skillpm-backup.$ts"
    warning "Detected legacy skillpm skills; migrating to apm"
    if [[ -e "$skills_dir" && ! -L "$skills_dir" ]]; then
        mv "$skills_dir" "$backup"
        info "Backed up ~/.claude/skills -> $backup"
    elif [[ -L "$skills_dir" ]]; then
        rm -f "$skills_dir"
    fi
    if [[ -d "$HOME/.agents/skills" ]]; then
        mv "$HOME/.agents/skills" "$HOME/.agents/skills.skillpm-backup.$ts"
    fi
    rm -f "$HOME/.agents/.skill-lock.json"
}

install_skills() {
    info "Installing skills via apm..."

    if ! ensure_apm; then
        return 0
    fi

    cleanup_legacy_skillpm

    # dotfiles の宣言的マニフェスト (.apm/apm.yml) をグローバルの正本として配置し、
    # apm install -g で ~/.claude/skills へ展開する。apm はインストール時に
    # ~/.apm/apm.yml を書き換えるため symlink せず copy する (settings.json と同じ
    # 「dotfiles が正、再実行で再適用」方針)。
    if [[ ! -f "$DOTFILES_DIR/.apm/apm.yml" ]]; then
        warning "$DOTFILES_DIR/.apm/apm.yml not found; skipping skills"
        return 0
    fi
    mkdir -p "$HOME/.apm"
    install -m 644 "$DOTFILES_DIR/.apm/apm.yml" "$HOME/.apm/apm.yml"

    # Local apm primitives (agents) live under .apm/<type>/. Mirror them into
    # ~/.apm so `apm install -g` deploys them to ~/.claude/agents alongside the
    # dependency skills. Clean-sync so a primitive deleted from dotfiles is also
    # removed globally on the next run.
    rm -rf "$HOME/.apm/agents"
    if [[ -d "$DOTFILES_DIR/.apm/agents" ]]; then
        cp -R "$DOTFILES_DIR/.apm/agents" "$HOME/.apm/agents"
    fi

    if apm install -g --target claude; then
        success "Skills and agents installed via apm"
    else
        warning "apm install reported issues; check 'apm install -g' output"
    fi
}

# ---- Main ----

link_claude
apply_claude_settings
install_skills

# Sync rules to Codex/Copilot
info "Syncing rules to Codex/Copilot..."
bash "$DOTFILES_DIR/scripts/sync-rules.sh" --global

success "Claude Code configuration installed"
