#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

FAILED=0
NVIM_CONFIG_DIR="$(cd "$(dirname "$0")/.." && pwd)/.config/nvim"

# ---------------------------------------------------------------------------
# 1. Headless startup check
# ---------------------------------------------------------------------------
test_startup() {
  info "Checking Neovim headless startup..."
  local stderr_file
  stderr_file=$(mktemp)
  if nvim --headless +"qall!" 2>"$stderr_file"; then
    # Filter out known harmless messages
    local errors
    errors=$(grep -viE '(^$|warning|deprecated)' "$stderr_file" || true)
    if [[ -z "$errors" ]]; then
      success "Neovim starts without errors"
    else
      error "Neovim startup produced errors:"
      cat "$stderr_file" >&2
      FAILED=1
    fi
  else
    error "Neovim failed to start (exit code: $?)"
    cat "$stderr_file" >&2
    FAILED=1
  fi
  rm -f "$stderr_file"
}

# ---------------------------------------------------------------------------
# 2. Module require check
# ---------------------------------------------------------------------------
test_modules() {
  info "Checking module require..."
  local modules=("plugins.ui" "plugins.lsp" "plugins.editor" "config.lazy")
  for mod in "${modules[@]}"; do
    local stderr_file
    stderr_file=$(mktemp)
    if nvim --headless +"lua require('$mod')" +"qall!" 2>"$stderr_file"; then
      success "require('$mod')"
    else
      error "require('$mod') failed"
      cat "$stderr_file" >&2
      FAILED=1
    fi
    rm -f "$stderr_file"
  done
}

# ---------------------------------------------------------------------------
# 3. Startup time check (requires hyperfine)
# ---------------------------------------------------------------------------
test_startuptime() {
  local threshold_ms=200
  info "Checking startup time (threshold: ${threshold_ms}ms)..."

  if ! command_exists hyperfine; then
    warning "hyperfine not found, skipping startup time check"
    return 0
  fi

  local json_file
  json_file=$(mktemp)
  hyperfine --warmup 3 --min-runs 5 --shell=none \
    "nvim --headless +qall!" --export-json "$json_file" >/dev/null 2>&1

  local mean_s
  mean_s=$(jq '.results[0].mean' "$json_file")
  local mean_ms
  mean_ms=$(echo "$mean_s * 1000" | bc | cut -d. -f1)
  rm -f "$json_file"

  if [[ "$mean_ms" -le "$threshold_ms" ]]; then
    success "Startup time: ${mean_ms}ms (<= ${threshold_ms}ms)"
  else
    error "Startup time: ${mean_ms}ms (> ${threshold_ms}ms)"
    FAILED=1
  fi
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------
echo ""
info "=== Neovim Smoke Tests ==="
echo ""

test_startup
test_modules
test_startuptime

echo ""
if [[ "$FAILED" -ne 0 ]]; then
  error "Some tests failed"
  exit 1
else
  success "All tests passed"
fi
