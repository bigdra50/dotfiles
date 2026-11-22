#!/usr/bin/env bash
# Markdown の文体検査に使う textlint を、dotfiles の .claude/node_modules へ入れる。
#
# `mise run setup:claude` と、chezmoi の run_onchange スクリプトの両方がここを呼ぶ。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLAUDE_DIR="$DOTFILES_DIR/.claude"
source "$DOTFILES_DIR/scripts/lib.sh"

# .claude/hooks/textlint-*.sh は $CLAUDE_DIR/node_modules/.bin/textlint を
# 見つけられないと黙って素通しする（フェイルオープン）。設定だけ追跡されていて
# 実体が入っていない状態を避けるため、セットアップで必ず入れる。
#
# setup:claude は setup:platform-tools に依存していないので、初回 setup の時点で
# node が未導入のことがある。その場合は入れずに進む。2回目の setup:claude で入る。
ensure_textlint() {
    if ! command_exists npm; then
        warning "npm not found; skipping textlint install (md lint hooks will no-op)"
        return 0
    fi
    if [[ ! -f "$CLAUDE_DIR/package-lock.json" ]]; then
        warning "$CLAUDE_DIR/package-lock.json not found; skipping textlint install"
        return 0
    fi

    info "Installing textlint into $CLAUDE_DIR/node_modules..."
    # --ignore-scripts: 依存の install lifecycle script を走らせない。
    # 現在の依存に install script を持つパッケージは無いので副作用は無い。
    if npm ci --prefix "$CLAUDE_DIR" --no-audit --no-fund --ignore-scripts >/dev/null 2>&1; then
        success "textlint installed"
    else
        warning "npm ci failed in $CLAUDE_DIR; md lint hooks will no-op"
    fi
}

# テストが source して関数単位で呼べるよう、直接実行したときだけ走らせる
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    ensure_textlint
fi
