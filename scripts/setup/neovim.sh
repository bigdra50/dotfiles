#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$DOTFILES_DIR/scripts/lib.sh"

info "Setting up Neovim environment..."

if ! command_exists uv; then
    warning "uv not found, skipping Neovim Python setup"
    exit 0
fi

mkdir -p "$HOME/.venvs"

if [[ -d "$HOME/.venvs/nvim" ]]; then
    # Check if venv is broken (e.g., python symlink points to removed interpreter)
    if [[ ! -x "$HOME/.venvs/nvim/bin/python3" ]]; then
        warning "Neovim venv is broken, recreating..."
        rm -rf "$HOME/.venvs/nvim"
        uv venv "$HOME/.venvs/nvim"
    else
        info "Neovim venv already exists, updating packages..."
    fi
else
    info "Creating Neovim Python environment..."
    uv venv "$HOME/.venvs/nvim"
fi

info "Installing neovim Python package..."
cd "$HOME/.venvs/nvim"
uv pip install neovim

success "Neovim Python environment ready"

if command_exists npm; then
    info "Installing Neovim Node.js provider..."
    npm install -g neovim@latest
    success "Neovim Node.js provider installed"
fi
