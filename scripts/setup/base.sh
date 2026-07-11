#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$DOTFILES_DIR/scripts/lib.sh"

PLATFORM=$(detect_platform)
ARCH=$(detect_arch)

info "Installing base tools for $PLATFORM ($ARCH)..."

case "$PLATFORM" in
    macos)
        if ! command_exists brew; then
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            if [[ "$ARCH" == "aarch64" ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi
        else
            success "Homebrew already installed"
        fi
        ;;
    linux | wsl)
        if command_exists apt-get; then
            info "Updating apt packages..."
            sudo apt-get update
            sudo apt-get install -y curl git build-essential zsh
        elif command_exists dnf; then
            sudo dnf install -y curl git gcc gcc-c++ make zsh
        elif command_exists pacman; then
            sudo pacman -Syu --noconfirm curl git base-devel zsh
        fi
        ;;
esac

success "Base tools installed"

# ---- Default shell ----
# dotfiles の設定は zsh 前提なので、ログインシェルを zsh に切り替える。
# passwordless sudo → 対話 tty → 手動案内 の順にフォールバックする fail-open 実装
# (bootstrap の非対話実行でもハングさせない。macOS は既定が zsh なので早期 return)。
set_default_shell_zsh() {
    local zsh_path current_shell
    zsh_path="$(command -v zsh || true)"
    [[ -z "$zsh_path" ]] && {
        warning "zsh not found; skipping default shell switch"
        return 0
    }

    current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
    [[ -z "$current_shell" ]] && current_shell="${SHELL:-}"
    if [[ "$current_shell" == */zsh ]]; then
        success "Default shell already zsh ($current_shell)"
        return 0
    fi

    # zsh を /etc/shells に登録 (未登録だと chsh が拒否する)。権限が要るので best-effort
    if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null 2>&1 || true
    fi

    info "Switching default shell to zsh ($zsh_path)..."
    if sudo -n true 2>/dev/null && sudo chsh -s "$zsh_path" "$USER" 2>/dev/null; then
        success "Default shell set to zsh (re-login to apply)"
    elif [[ "${INTERACTIVE:-true}" != "false" && -t 0 ]] && chsh -s "$zsh_path" 2>/dev/null; then
        success "Default shell set to zsh (re-login to apply)"
    else
        warning "Could not switch default shell automatically. Run:  chsh -s $zsh_path"
    fi
}

set_default_shell_zsh
