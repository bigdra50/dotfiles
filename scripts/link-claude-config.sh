#!/usr/bin/env bash
# =============================================================================
# Claude Configuration Symlink Utility
# =============================================================================
# This script creates symlinks for .claude directory contents to ~/.claude/
#
# Usage:
#   ./link-claude-config.sh                    # Interactive mode
#   ./link-claude-config.sh --force            # Overwrite existing files
#   ./link-claude-config.sh --dry-run          # Preview changes only
#   ./link-claude-config.sh --selective        # Choose which items to link
#
# Requirements: bash 3.2 or later

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(dirname "$SCRIPT_DIR")}"
CLAUDE_SOURCE_DIR="${DOTFILES_DIR}/.claude"
CLAUDE_TARGET_DIR="${HOME}/.claude"

# Items to link (files and directories)
CLAUDE_ITEMS=(
    "CLAUDE.md"
    "agents"
    "commands"
    "settings.json"
    "tools"
    "docs"
)

# =============================================================================
# Color Output Functions
# =============================================================================

# Check if terminal supports colors
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    BLUE=$(tput setaf 4)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RED=$(tput setaf 1)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    BLUE=""
    GREEN=""
    YELLOW=""
    RED=""
    CYAN=""
    BOLD=""
    RESET=""
fi

info() {
    echo "${BLUE}==>${RESET} $*"
}

success() {
    echo "${GREEN}✓${RESET} $*"
}

warn() {
    echo "${YELLOW}!${RESET} $*"
}

error() {
    echo "${RED}✗${RESET} $*" >&2
}

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat <<EOF
${BOLD}Claude Configuration Symlink Utility${RESET}

${BOLD}Usage:${RESET}
  $0 [OPTIONS]

${BOLD}Options:${RESET}
  --force              Overwrite existing files without prompting
  --dry-run            Preview changes without making them
  --selective          Choose which items to link interactively
  --help               Show this help message

${BOLD}Examples:${RESET}
  $0                    # Interactive mode
  $0 --force            # Auto-overwrite
  $0 --dry-run          # Preview only
  $0 --selective        # Select items

${BOLD}Items that will be linked:${RESET}
  - CLAUDE.md
  - agents/
  - commands/
  - settings.json
  - tools/
  - docs/

${BOLD}Paths:${RESET}
  Source: ${CLAUDE_SOURCE_DIR}
  Target: ${CLAUDE_TARGET_DIR}
EOF
}

create_symlink() {
    local item_name="$1"
    local dry_run="$2"
    local force="$3"

    local source="${CLAUDE_SOURCE_DIR}/${item_name}"
    local target="${CLAUDE_TARGET_DIR}/${item_name}"

    # Check if source exists
    if [[ ! -e "$source" ]]; then
        warn "Source not found: ${item_name} (skipping)"
        return 1
    fi

    # Dry run mode
    if [[ "$dry_run" == "true" ]]; then
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            info "[DRY RUN] ${item_name} (already linked correctly)"
        elif [[ -e "$target" ]]; then
            warn "[DRY RUN] ${item_name} (would be overwritten)"
        else
            info "[DRY RUN] ${item_name} (would be created)"
        fi
        return 0
    fi

    # Check if target already exists
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        # Already correctly linked
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            success "${item_name} (already linked)"
            return 0
        fi

        # Handle existing file/directory
        if [[ "$force" != "true" ]]; then
            warn "${item_name} already exists"
            read -rp "  Overwrite? [y/N] " response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                warn "Skipping ${item_name}"
                return 1
            fi
        fi

        # Backup existing file/directory
        if [[ ! -L "$target" ]]; then
            local timestamp
            timestamp=$(date +%Y%m%d_%H%M%S)
            local backup="${target}.backup.${timestamp}"
            mv "$target" "$backup"
            info "Backed up to $(basename "$backup")"
        else
            rm "$target"
        fi
    fi

    # Create symlink
    if ln -s "$source" "$target"; then
        success "${item_name}"
        return 0
    else
        error "Failed to create symlink for ${item_name}"
        return 1
    fi
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    local force="false"
    local dry_run="false"
    local selective="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force="true"
                shift
                ;;
            --dry-run)
                dry_run="true"
                shift
                ;;
            --selective)
                selective="true"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    echo ""
    echo "${CYAN}╔════════════════════════════════════════════════╗${RESET}"
    echo "${CYAN}║${RESET}  ${BLUE}🔗 Claude Configuration Symlink Utility   ${RESET}${CYAN}║${RESET}"
    echo "${CYAN}╚════════════════════════════════════════════════╝${RESET}"
    echo ""

    # Check if source directory exists
    if [[ ! -d "$CLAUDE_SOURCE_DIR" ]]; then
        error "Source directory not found: ${CLAUDE_SOURCE_DIR}"
        exit 1
    fi

    info "Source: ${CLAUDE_SOURCE_DIR}"
    info "Target: ${CLAUDE_TARGET_DIR}"

    if [[ "$dry_run" == "true" ]]; then
        info "Mode: DRY RUN (no changes will be made)"
    elif [[ "$force" == "true" ]]; then
        info "Mode: FORCE (auto-overwrite)"
    elif [[ "$selective" == "true" ]]; then
        info "Mode: SELECTIVE"
    else
        info "Mode: INTERACTIVE"
    fi

    echo ""

    # Create target directory if it doesn't exist
    if [[ "$dry_run" != "true" ]] && [[ ! -d "$CLAUDE_TARGET_DIR" ]]; then
        info "Creating target directory: ${CLAUDE_TARGET_DIR}"
        mkdir -p "$CLAUDE_TARGET_DIR"
    fi

    # Selective mode: let user choose items
    local items_to_link=("${CLAUDE_ITEMS[@]}")
    if [[ "$selective" == "true" ]] && [[ "$dry_run" != "true" ]]; then
        echo "${BLUE}Select items to link:${RESET}"
        local selected_items=()
        for item in "${CLAUDE_ITEMS[@]}"; do
            local source="${CLAUDE_SOURCE_DIR}/${item}"
            if [[ -e "$source" ]]; then
                read -rp "  Link ${item}? [Y/n] " response
                if [[ ! "$response" =~ ^[Nn]$ ]]; then
                    selected_items+=("$item")
                fi
            else
                warn "  ${item} not found in source (skipping)"
            fi
        done
        items_to_link=("${selected_items[@]}")
        echo ""
    fi

    # Create symlinks
    info "Creating symlinks..."
    echo ""

    local success_count=0
    local fail_count=0

    for item in "${items_to_link[@]}"; do
        if create_symlink "$item" "$dry_run" "$force"; then
            ((success_count++)) || true
        else
            ((fail_count++)) || true
        fi
    done

    # Summary
    echo ""
    echo "${CYAN}╔════════════════════════════════════════════════╗${RESET}"
    if [[ "$dry_run" == "true" ]]; then
        echo "${CYAN}║${RESET}  ${BLUE}📋 Dry Run Complete                       ${RESET}${CYAN}║${RESET}"
    else
        echo "${CYAN}║${RESET}  ${GREEN}✨ Linking Complete                       ${RESET}${CYAN}║${RESET}"
    fi
    echo "${CYAN}╚════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "${BLUE}Summary:${RESET}"
    echo "  Success: ${success_count}"
    if [[ $fail_count -gt 0 ]]; then
        echo "  ${RED}Failed:  ${fail_count}${RESET}"
    fi
    echo ""

    if [[ "$dry_run" == "true" ]]; then
        info "This was a dry run. Run without --dry-run to apply changes."
        echo ""
    fi
}

# Run main function
main "$@"
