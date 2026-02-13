#!/usr/bin/env bash
# =============================================================================
# Shared Library for Dotfiles Scripts
# =============================================================================
# Source this file from other scripts:
#   source "$SCRIPT_DIR/scripts/lib.sh"   # from repo root
#   source "$SCRIPT_DIR/lib.sh"           # from scripts/
#   source "$(dirname "$SCRIPT_DIR")/scripts/lib.sh"  # from subdirectories

# Guard against multiple sourcing
[[ -n "${_LIB_SH_LOADED:-}" ]] && return 0
_LIB_SH_LOADED=1

# =============================================================================
# Color Definitions
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# Logging Functions
# =============================================================================

info() {
    echo -e "${BLUE}==>${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# =============================================================================
# Utility Functions
# =============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            echo "$(uname -m)"
            ;;
    esac
}

# =============================================================================
# Symlink Management
# =============================================================================

# Create a symlink with backup support
# Usage: create_symlink <source> <target>
# Requires INTERACTIVE variable to be set (defaults to "true")
create_symlink() {
    local source="$1"
    local target="$2"
    local interactive="${INTERACTIVE:-true}"

    # If target exists
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        # If it's already the correct symlink, skip
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            success "$target (already linked)"
            return 0
        fi

        # Handle based on interactive mode
        if [[ "$interactive" == "false" ]]; then
            if [[ ! -L "$target" ]]; then
                local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "$target" "$backup"
                info "Backed up to $backup"
            else
                rm "$target"
            fi
        else
            warning "$target already exists"
            read -p "  Overwrite? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                warning "Skipping $target"
                return 0
            fi

            if [[ ! -L "$target" ]]; then
                local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
                mv "$target" "$backup"
                info "Backed up to $backup"
            else
                rm "$target"
            fi
        fi
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    ln -s "$source" "$target"
    success "$target"
}

# =============================================================================
# Network Helpers
# =============================================================================

# Retry wrapper for network operations
# Usage: retry_command <command> [args...]
retry_command() {
    local max_retries="${MAX_RETRIES:-4}"
    local delay="${RETRY_DELAY:-2}"
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        if "$@"; then
            return 0
        else
            if [ $attempt -lt $max_retries ]; then
                warning "Command failed (attempt $attempt/$max_retries). Retrying in ${delay}s..."
                sleep $delay
                delay=$((delay * 2))
                attempt=$((attempt + 1))
            else
                error "Command failed after $max_retries attempts"
                return 1
            fi
        fi
    done
}
