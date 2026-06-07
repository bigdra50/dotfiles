#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CONFIG_DUMP="$(mktemp)"
CLEAN_DUMP="$(mktemp)"
trap 'rm -f "${CONFIG_DUMP}" "${CLEAN_DUMP}"' EXIT

# nvim stdout goes to stderr: on a cold cache, lazy.nvim and nvim-treesitter
# print install progress to stdout, which would corrupt this script's JSON
# output. The keymap dump itself is written to KB_DUMP_PATH, not stdout.
KB_DUMP_PATH="${CONFIG_DUMP}" nvim --headless \
  '+Lazy! load all' \
  "+luafile ${SCRIPT_DIR}/nvim_dump.lua" \
  '+qall!' 1>&2

KB_DUMP_PATH="${CLEAN_DUMP}" nvim --clean --headless \
  "+luafile ${SCRIPT_DIR}/nvim_dump.lua" \
  '+qall!' 1>&2

python3 "${SCRIPT_DIR}/extract_nvim.py" \
  --config-json "${CONFIG_DUMP}" \
  --clean-json "${CLEAN_DUMP}"
