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
    linux|wsl)
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
