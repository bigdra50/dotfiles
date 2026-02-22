#!/usr/bin/env bash
# =============================================================================
# Tool Audit Script
# miseで管理すべきツールが他の場所にインストールされていないかチェック
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
info() { echo -e "${BLUE}==>${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
error() { echo -e "${RED}✗${NC}  $1"; }
success() { echo -e "${GREEN}✓${NC}  $1"; }
header() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

# Config
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MISE_CONFIG="$DOTFILES_DIR/mise/config.toml"

# 許可リスト（意図的にmise外で管理するツール）
# 依存関係がある、または特殊用途のツール
ALLOWED_BREW=("python" "ruby" "fastlane")  # 他のbrewパッケージが依存 / mise gem backend非対応
ALLOWED_NPM=("upm-lsp")  # ローカル開発パッケージ
ALLOWED_PIPX=("magi")  # fbprophet依存がビルド不可

# 配列に含まれるかチェック
in_array() {
    local needle="$1"
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# miseで管理したいツール一覧（mise/config.tomlから抽出）
get_mise_managed_tools() {
    if [[ -f "$MISE_CONFIG" ]]; then
        grep -E '^\w+\s*=' "$MISE_CONFIG" | \
            grep -v '^\[' | \
            sed 's/\s*=.*//' | \
            sed 's/"//g' | \
            sort -u
    fi
}

# =============================================================================
# 検出関数
# =============================================================================

# brew vs mise 重複チェック
check_brew_duplicates() {
    header "Homebrew重複チェック"

    if ! command -v brew &>/dev/null; then
        info "Homebrewがインストールされていません"
        return 0
    fi

    local mise_tools=$(get_mise_managed_tools)
    local found=0

    for tool in $mise_tools; do
        # miseプレフィックスを除去
        local clean_tool=$(echo "$tool" | sed 's/^cargo://; s/^pipx://; s/^ubi:[^/]*\///')

        if brew list "$clean_tool" &>/dev/null 2>&1; then
            if in_array "$clean_tool" "${ALLOWED_BREW[@]}"; then
                info "$clean_tool (brew依存関係のため許可)"
            else
                warn "$clean_tool がbrew経由でもインストール済み"
                echo "      修正: brew uninstall $clean_tool"
                found=$((found + 1))
            fi
        fi
    done

    if [[ $found -eq 0 ]]; then
        success "重複なし"
    else
        echo ""
        warn "重複: $found 件"
    fi
}

# cargo bin チェック
check_cargo_orphans() {
    header "Cargo孤立バイナリチェック"

    local cargo_bin="$HOME/.cargo/bin"
    if [[ ! -d "$cargo_bin" ]]; then
        info "~/.cargo/bin が存在しません"
        return 0
    fi

    local found=0
    for bin in "$cargo_bin"/*; do
        [[ ! -e "$bin" ]] && continue
        local name=$(basename "$bin")

        # miseで管理されているか確認
        if ! mise which "$name" &>/dev/null 2>&1; then
            # ただしcargo自体のツールは除外
            case "$name" in
                cargo|cargo-*|rustc|rustdoc|rustfmt|rust-*|clippy-driver)
                    continue
                    ;;
            esac
            warn "$name がcargo binに孤立"
            echo "      経路: $bin"
            found=$((found + 1))
        fi
    done

    if [[ $found -eq 0 ]]; then
        success "孤立バイナリなし"
    else
        echo ""
        warn "孤立: $found 件"
        echo "      修正: rm ~/.cargo/bin/<tool> または mise use cargo:<tool>"
    fi
}

# go bin チェック
check_go_orphans() {
    header "Go孤立バイナリチェック"

    local go_bin="$HOME/go/bin"
    if [[ ! -d "$go_bin" ]]; then
        info "~/go/bin が存在しません"
        return 0
    fi

    local found=0
    for bin in "$go_bin"/*; do
        [[ ! -e "$bin" ]] && continue
        local name=$(basename "$bin")

        # miseで管理されているか確認
        if ! mise which "$name" &>/dev/null 2>&1; then
            warn "$name がgo binに孤立"
            echo "      経路: $bin"
            found=$((found + 1))
        fi
    done

    if [[ $found -eq 0 ]]; then
        success "孤立バイナリなし"
    else
        echo ""
        warn "孤立: $found 件"
        echo "      修正: rm ~/go/bin/<tool> または mise.tomlに追加"
    fi
}

# npm -g チェック
check_npm_globals() {
    header "npm globalパッケージチェック"

    if ! command -v npm &>/dev/null; then
        info "npmがインストールされていません"
        return 0
    fi

    local globals=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | sed 's/.*── //' | sed 's/@.*//')
    local found=0

    for pkg in $globals; do
        [[ -z "$pkg" ]] && continue
        # 基本パッケージは除外
        case "$pkg" in
            npm|corepack)
                continue
                ;;
        esac

        # miseで管理されているか確認
        if ! mise list 2>/dev/null | grep -qw "npm:$pkg"; then
            if in_array "$pkg" "${ALLOWED_NPM[@]}"; then
                info "$pkg (MCP/拡張のため許可)"
            else
                warn "$pkg がnpm -gでインストール済み"
                echo "      修正: npm uninstall -g $pkg && mise use npm:$pkg"
                found=$((found + 1))
            fi
        fi
    done

    if [[ $found -eq 0 ]]; then
        success "孤立パッケージなし"
    else
        echo ""
        warn "孤立: $found 件"
    fi
}

# pip/pipx チェック
check_pip_globals() {
    header "pip/pipxグローバルパッケージチェック"

    # pipx確認
    if command -v pipx &>/dev/null; then
        local pipx_pkgs=$(pipx list --short 2>/dev/null | awk '{print $1}')
        local found=0

        for pkg in $pipx_pkgs; do
            [[ -z "$pkg" ]] && continue
            if ! mise list 2>/dev/null | grep -qw "pipx:$pkg"; then
                if in_array "$pkg" "${ALLOWED_PIPX[@]}"; then
                    info "$pkg (特殊用途のため許可)"
                else
                    warn "$pkg がpipxでインストール済み"
                    echo "      修正: pipx uninstall $pkg && mise use pipx:$pkg"
                    found=$((found + 1))
                fi
            fi
        done

        if [[ $found -eq 0 ]]; then
            success "pipx孤立パッケージなし"
        fi
    fi
}

# PATH優先順位チェック
check_path_priority() {
    header "PATH優先順位チェック"

    local mise_shims="$HOME/.local/share/mise/shims"
    local path_array=(${PATH//:/ })
    local mise_pos=-1
    local brew_pos=-1
    local cargo_pos=-1

    for i in "${!path_array[@]}"; do
        case "${path_array[$i]}" in
            *mise/shims*)
                [[ $mise_pos -eq -1 ]] && mise_pos=$i
                ;;
            /opt/homebrew/bin|/usr/local/bin)
                [[ $brew_pos -eq -1 ]] && brew_pos=$i
                ;;
            */.cargo/bin)
                [[ $cargo_pos -eq -1 ]] && cargo_pos=$i
                ;;
        esac
    done

    if [[ $mise_pos -ne -1 ]]; then
        if [[ $brew_pos -ne -1 ]] && [[ $mise_pos -gt $brew_pos ]]; then
            warn "mise shimsがbrewより後にある (mise: $mise_pos, brew: $brew_pos)"
            echo "      mise shimsを先にすることを推奨"
        elif [[ $cargo_pos -ne -1 ]] && [[ $mise_pos -gt $cargo_pos ]]; then
            warn "mise shimsがcargoより後にある"
        else
            success "mise shimsが適切な優先順位"
        fi
    else
        warn "mise shimsがPATHにありません"
    fi
}

# =============================================================================
# サマリー表示
# =============================================================================

show_summary() {
    header "サマリー"

    echo "mise管理ツール数: $(mise list 2>/dev/null | wc -l | tr -d ' ')"
    echo "mise設定ファイル: $MISE_CONFIG"
    echo ""
    echo "推奨アクション:"
    echo "  1. 重複ツールをbrewからアンインストール"
    echo "  2. 孤立バイナリを削除またはmiseに移行"
    echo "  3. 定期的にこのスクリプトを実行"
}

# =============================================================================
# メイン
# =============================================================================

main() {
    echo -e "${CYAN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BLUE}🔍 Tool Audit${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════╝${NC}"

    check_path_priority
    check_brew_duplicates
    check_cargo_orphans
    check_go_orphans
    check_npm_globals
    check_pip_globals
    show_summary
}

main "$@"
