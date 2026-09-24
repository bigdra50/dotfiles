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

cleanup_obsolete_links() {
    local obsolete_links=(
        "$HOME/.zsh"
        "$HOME/.zshrc"
        "$HOME/.Brewfile"
        "$HOME/.mise.toml"
    )

    for path in "${obsolete_links[@]}"; do
        if [[ -L "$path" ]] && [[ ! -e "$path" ]]; then
            rm "$path"
            info "Removed obsolete symlink $path"
        fi
    done
}

# ---- Root-level dotfiles ----

link_dotfiles() {
    info "Creating symlinks for dotfiles..."
    local excludes
    excludes=$(get_excludes)

    for file in "$DOTFILES_DIR"/.*; do
        [[ ! -e "$file" ]] && continue
        local basename
        basename=$(basename "$file")

        if echo " $excludes " | grep -q " $basename "; then
            continue
        fi

        if [[ -d "$file" ]]; then
            case "$basename" in
                ".config" | ".claude") continue ;;
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

    # Migrate the old "~/.config -> dotfiles/.config" layout to the new
    # per-entry symlink layout before creating individual links.
    if [[ -L "$HOME/.config" ]] && [[ -d "$HOME/.config" ]] && [[ "$HOME/.config" -ef "$DOTFILES_DIR/.config" ]]; then
        rm "$HOME/.config"
        info "Migrated legacy ~/.config symlink to directory layout"
    fi

    mkdir -p "$HOME/.config"

    for config in "$DOTFILES_DIR/.config"/*; do
        [[ ! -e "$config" ]] && continue
        local basename
        basename=$(basename "$config")

        if [[ "$basename" =~ \.backup\. ]] || [[ "$basename" == ".DS_Store" ]]; then
            continue
        fi

        # Cursor は cli-config.json へ認証情報を書き込み、同じディレクトリに会話履歴も置く。
        # リンクするとそれらがリポジトリへ書かれるので、apply_cursor_config が合成で当てる。
        if [[ "$basename" == "cursor" ]]; then
            continue
        fi

        case "$PLATFORM" in
            linux | wsl)
                if [[ "$basename" == "posh" || "$basename" == "yashiki" ]]; then
                    warning "Skipping $basename (macOS only)"
                    continue
                fi
                ;;
        esac

        create_symlink "$config" "$HOME/.config/$basename"
    done
}

# ---- Cursor CLI config ----

# 追跡中の cli-config.json には、最初にディレクトリごとリンクしたマシンの設定が丸ごと入っている。
# statusLine や sandbox はマシンごとに違うので、全マシンへ当てるのは attribution だけにする。
CURSOR_MANAGED_KEYS='["attribution"]'

apply_cursor_config() {
    local repo_dir="$DOTFILES_DIR/.config/cursor"
    local live_dir="$HOME/.config/cursor"
    [[ -f "$repo_dir/cli-config.json" ]] || return 0
    if ! command_exists jq; then
        warning "jq not found; skipping Cursor CLI config"
        return 0
    fi

    # 以前の構成では ~/.config/cursor がリポジトリを指していた。
    # Cursor が書いた設定と実行時ファイルを写し取り、実ディレクトリへ置き換える。
    # リポジトリ側に残る実行時ファイルは .gitignore 済みなので、消すのは本人の判断に任せる。
    if [[ -L "$live_dir" ]] && [[ "$live_dir" -ef "$repo_dir" ]]; then
        rm "$live_dir"
        mkdir -p "$live_dir"
        cp -a "$repo_dir/." "$live_dir/"
        warning "Replaced the $live_dir symlink with a real directory (copied from $repo_dir)"
    fi

    # Cursor が最初の起動で書く前に部分的なファイルを置かない。version などの初期値は Cursor に任せる。
    if [[ ! -f "$live_dir/cli-config.json" ]]; then
        info "Cursor CLI config not found; skipping (run setup again after starting Cursor once)"
        return 0
    fi

    local managed status=0
    managed="$(mktemp)"
    jq --argjson keys "$CURSOR_MANAGED_KEYS" \
        'with_entries(select(.key as $k | $keys | index($k)))' \
        "$repo_dir/cli-config.json" >"$managed"
    merge_json_onto "$managed" "$live_dir/cli-config.json" || status=$?
    rm -f "$managed"
    return "$status"
}

# ---- .ssh ----

link_ssh() {
    info "Creating symlink for .ssh/config..."
    [[ ! -f "$DOTFILES_DIR/.ssh/config" ]] && return 0

    # ディレクトリ全体は鍵を含むため repo 管理しない。config のみ file-level で link し、
    # マシン/プロファイル固有ホストの差し込み先 config.d/ を用意する。
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    create_symlink "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    mkdir -p "$HOME/.ssh/config.d"
    chmod 700 "$HOME/.ssh/config.d"
}

# ---- Main ----

main() {
    cleanup_obsolete_links
    link_dotfiles
    link_config
    apply_cursor_config
    link_ssh

    success "Symlinks created"
}

# テストが source して関数単位で呼べるよう、直接実行したときだけ main を走らせる
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
