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

### Debugging and Maintenance
- `just validate` - Validate justfile syntax
- `just fmt` - Format justfile
- `just setup-nvim` - Setup Neovim Python environment
- `INTERACTIVE=false just init` - Non-interactive installation (for CI/automation)

### Skills Management
- Skills are directly committed to `.claude/skills/` (flat structure required by Claude Code)
- Symlinked to `~/.claude/skills/` for all projects via `just link`

## Architecture

The repository follows a modular structure:

1. **Zsh Configuration** (`.zsh/`)
   - Main entry: `.zshrc` (loads environment, interface, and extensions)
   - Modular structure: environment.zsh, interface.zsh, extensions.zsh
   - Plugin system in `.zsh/plugins/` (bat, fzf, ripgrep, zoxide, etc.)
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

6. **Claude Code Skills** (`.claude/skills/`)
   - Flat directory structure (required by Claude Code)
   - Sourced from [anthropics/skills](https://github.com/anthropics/skills)
   - Key skills included:
     - `mcp-builder` - MCP server development guide
     - `skill-creator` - Custom skill creation guide
     - `webapp-testing` - Playwright-based web app testing
     - `document-skills` - PDF, DOCX, XLSX, PPTX processing
     - `artifacts-builder` - React artifact creation
     - `algorithmic-art` - p5.js generative art
     - See `.claude/skills/README.md` for full list
   - **Note**: Must use flat structure - nested directories (e.g., `skills/category/skill`) are not recognized by Claude Code

## Important Notes

- Repository location: `~/dev/github.com/bigdra50/dotfiles` (ghq root: `~/dev`)
- Development tools are managed via `mise` (go, rust, neovim, nodejs, etc.)
- Cargo tools automatically available via `~/.cargo/bin` in PATH (.zshenv)
- Local configuration overrides supported (`.zshrc_local`, `.gitconfig_local`, `.zshenv_local`)
- Backup system: existing files are automatically backed up during installation
- Docker testing environment available for validation

### Zsh Configuration Loading Order
1. `.zshenv` - Environment variables and PATH setup
2. `.zshrc` - Main configuration file that loads:
   - `~/.zsh/environment.zsh` - mise activation, colors, Go setup
   - `~/.zsh/interface.zsh` - Starship prompt, vi bindings, shell options
   - `~/.zsh/extensions.zsh` - Plugin loading and tool integrations
   - `~/.zshrc_local` - Local overrides (if exists)

### Tool Installation Process
1. Base tools installed via platform package managers (brew/apt)
2. Rust tools installed via cargo-binstall for speed
3. Go tools installed via `go install`
4. Runtime environments managed via mise
5. Special tools (fzf, wezterm) handled via fallback configurations

## Recent Improvements

- Docker environment for testing and validation
- Comprehensive tool management via tools.toml
- Automatic cargo tools PATH integration
- .config directory handling improvements
- Cross-platform installation scripts
- Bootstrap script for one-liner installation
- Anthropic skills integration (flat structure)