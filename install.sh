#!/usr/bin/env bash
# =============================================================================
# Dotfiles Installation Script
# =============================================================================
# Thin wrapper that delegates to mise tasks.
#
# Usage:
#   ./install.sh                    # Full setup
#   ./install.sh --only symlinks    # Specific steps
#   ./install.sh --help             # Show help

set -euo pipefail
cd "$(dirname "$0")"

# Step name mapping (old name -> mise task name)
map_step() {
    case "$1" in
        base)     echo "setup:base" ;;
        tools)    echo "setup:platform-tools" ;;
        symlinks) echo "setup:symlinks" ;;
        config)   echo "setup:symlinks" ;;
        neovim)   echo "setup:neovim" ;;
        claude)   echo "setup:claude" ;;
        *)        echo "setup:$1" ;;
    esac
}

show_help() {
    cat <<EOF
Dotfiles Installation Script

Usage:
  $0 [OPTIONS]

Options:
  --help              Show this help message
  --non-interactive   Run in non-interactive mode
  --only STEPS        Run only specific steps (comma-separated)
                      Available: base, tools, symlinks, neovim, claude
                      Default: all steps

Examples:
  $0                              # Full installation
  $0 --only symlinks              # Symlinks only
  $0 --only symlinks,claude       # Multiple steps
  INTERACTIVE=false $0            # Non-interactive
EOF
}

# Ensure mise is available
ensure_mise() {
    if command -v mise &>/dev/null; then return; fi
    if [[ -x "$HOME/.local/bin/mise" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        return
    fi
    echo "mise not found. Installing..." >&2
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
}

main() {
    local only=""
    export INTERACTIVE="${INTERACTIVE:-true}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) show_help; exit 0 ;;
            --non-interactive) export INTERACTIVE=false; shift ;;
            --only) only="$2"; shift 2 ;;
            *) echo "Unknown option: $1" >&2; show_help; exit 1 ;;
        esac
    done

    ensure_mise
    mise trust .config/mise/config.toml 2>/dev/null || true
    mise trust mise.toml 2>/dev/null || true

    if [[ -n "$only" ]]; then
        IFS=',' read -ra STEPS <<< "$only"
        for step in "${STEPS[@]}"; do
            mise run "$(map_step "$step")"
        done
    else
        mise run setup
    fi
}

main "$@"
