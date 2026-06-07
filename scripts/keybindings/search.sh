#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
source scripts/lib.sh

CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/dotfiles/keybindings"
CACHE_JSON="${CACHE_DIR}/keybindings.json"
CACHE_TSV="${CACHE_DIR}/keybindings.tsv"

SOURCE_PATHS=(
  ".wezterm.lua"
  ".skhdrc"
  ".config/zsh"
  ".config/nvim"
  "scripts/keybindings"
)

cache_needs_refresh() {
  if [[ ! -f "${CACHE_TSV}" ]] || [[ ! -f "${CACHE_JSON}" ]]; then
    return 0
  fi
  if [[ "${KEYS_REFRESH:-}" == "1" ]]; then
    return 0
  fi
  local newer_files
  newer_files="$(find "${SOURCE_PATHS[@]}" -newer "${CACHE_TSV}" 2>/dev/null | head -1 || true)"
  [[ -n "${newer_files}" ]]
}

regenerate_cache() {
  info "extracting keybindings (first run takes a while)..."
  mkdir -p "${CACHE_DIR}"
  bash scripts/keybindings/extract.sh --out "${CACHE_JSON}"
  python3 scripts/keybindings/render.py \
    --input "${CACHE_JSON}" \
    --tsv \
    --out "${CACHE_TSV}"
}

if ! command_exists fzf; then
  error "fzf is required but not installed"
  exit 1
fi

if cache_needs_refresh; then
  regenerate_cache
fi

# fzf substitutes {n} with the n-th tab-delimited field of the selected line
preview_script='printf "tool:        %s\nmode:        %s\nkey:         %s\naction:      %s\ndescription: %s\norigin:      %s\nchange:      %s\nsource:      %s\n" {1} {2} {3} {4} {5} {6} {7} {8}'

fzf \
  --delimiter=$'\t' \
  --with-nth=1,2,3,4,5 \
  --nth=1,2,3,4,5 \
  --header='keybindings (tool/mode/key/action/description)' \
  --preview="${preview_script}" \
  --preview-window=right:45% \
  <"${CACHE_TSV}"
