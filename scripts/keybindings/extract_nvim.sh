#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

CONFIG_DUMP="$(mktemp)"
CLEAN_DUMP="$(mktemp)"
trap 'rm -f "${CONFIG_DUMP}" "${CLEAN_DUMP}"' EXIT

KB_DUMP_PATH="${CONFIG_DUMP}" nvim --headless \
  '+Lazy! load all' \
  "+luafile ${SCRIPT_DIR}/nvim_dump.lua" \
  '+qall!'

KB_DUMP_PATH="${CLEAN_DUMP}" nvim --clean --headless \
  "+luafile ${SCRIPT_DIR}/nvim_dump.lua" \
  '+qall!'

python3 "${SCRIPT_DIR}/extract_nvim.py" \
  --config-json "${CONFIG_DUMP}" \
  --clean-json "${CLEAN_DUMP}"
