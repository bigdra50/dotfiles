# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository that manages configuration files for various development tools and applications. The repository uses a symlink-based approach where dotfiles are stored in `~/dev/github.com/bigdra50/dotfiles` and symlinked to their expected locations in the home directory.

## Key Commands

### Installation and Setup
- `just init` - Main installation command (clones repo, installs tools, creates symlinks)
- `just install-tools` - Installs platform-specific tools from tools.toml
- `just link` - Creates symlinks from dotfiles to home directory
- `just clone` - Clones or updates dotfiles repository

### Development and Testing
- `just docker-test` - Test installation in Ubuntu container
- `just docker-shell` - Enter Ubuntu container shell
- `just info` - Show platform information
- `just unlink` - Remove all symlinks

## Architecture

The repository follows a modular structure:

1. **Zsh Configuration** (`.zsh/`)
   - Main entry: `.zshrc`
   - Modular plugins in `.zsh/plugins/`
   - Supports local overrides via `.zshrc_local`

2. **Tool Management** (`tools.toml`)
   - Cargo tools: Rust-based CLI tools (bat, eza, ripgrep, etc.)
   - Go tools: Go-based tools (ghq)
   - Platform-specific packages (Homebrew, apt, scoop)
   - Runtime management via mise

3. **Tool Configurations**
   - Git: `.gitconfig` (with delta pager, neovim diff)
   - Terminal: `.wezterm.lua`
   - Window Manager: `.yabairc`, `.skhdrc` (macOS)
   - PowerShell: `.config/posh/`
   - Development tools: `.mise.toml` (mise configuration)

4. **Installation System**
   - Uses `just` command runner
   - Automated tool installation via `tools.toml`
   - cargo-binstall for fast Rust tool installation
   - Platform detection (macOS, Linux, WSL)
   - Docker environment for testing

5. **Cross-platform Support**
   - Automatic platform detection
   - Platform-specific tool exclusions
   - Non-interactive mode support (`INTERACTIVE=false`)

## Important Notes

- Repository location: `~/dev/github.com/bigdra50/dotfiles` (ghq root: `~/dev`)
- Development tools are managed via `mise` (go, rust, neovim, nodejs, etc.)
- Cargo tools automatically available via `~/.cargo/bin` in PATH (.zshenv)
- Local configuration overrides supported (`.zshrc_local`, `.gitconfig_local`, `.zshenv_local`)
- Backup system: existing files are automatically backed up during installation
- Docker testing environment available for validation

## Recent Improvements

- Docker environment for testing and validation
- Comprehensive tool management via tools.toml
- Automatic cargo tools PATH integration
- .config directory handling improvements
- Cross-platform installation scripts
- Bootstrap script for one-liner installation