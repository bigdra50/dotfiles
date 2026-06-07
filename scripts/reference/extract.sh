#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
source scripts/lib.sh

SCRIPT_DIR="scripts/reference"
OUT_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --out)
            OUT_PATH="$2"
            shift 2
            ;;
        *)
            error "unknown argument: $1"
            exit 1
            ;;
    esac
done

TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "${TMPDIR_WORK}"' EXIT

ZSH_OUT="${TMPDIR_WORK}/zsh.json"
SKHD_OUT="${TMPDIR_WORK}/skhd.json"
WEZ_OUT="${TMPDIR_WORK}/wezterm.json"
NVIM_OUT="${TMPDIR_WORK}/nvim.json"
MERGED_OUT="${TMPDIR_WORK}/merged.json"

run_extractor() {
    local tool_name="$1"
    local output_file="$2"
    shift 2
    info "extracting ${tool_name} keybindings..."
    set +e
    "$@" >"${output_file}"
    local exit_status=$?
    set -e
    if [[ ${exit_status} -ne 0 ]]; then
        error "${tool_name} extractor failed (exit ${exit_status})"
        exit 1
    fi
    if ! python3 -c "
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
if not isinstance(data, list):
    sys.exit(1)
" "${output_file}"; then
        error "${tool_name} extractor produced invalid JSON (expected array)"
        exit 1
    fi
}

run_extractor "zsh" "${ZSH_OUT}" python3 "${SCRIPT_DIR}/extract_zsh.py" --root .
run_extractor "skhd" "${SKHD_OUT}" python3 "${SCRIPT_DIR}/extract_skhd.py" --root .
# --config-file is required: in CI $HOME has no .wezterm.lua, so the implicit
# config lookup would silently diff defaults against defaults (0 custom keys)
run_extractor "wezterm" "${WEZ_OUT}" python3 "${SCRIPT_DIR}/extract_wezterm.py" --config-file .wezterm.lua
run_extractor "nvim" "${NVIM_OUT}" bash "${SCRIPT_DIR}/extract_nvim.sh"

info "merging extractor outputs..."
python3 -c "
import json, sys

paths = sys.argv[1:]
merged = []
for path in paths:
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    if not isinstance(data, list):
        sys.exit(1)
    merged.extend(data)
json.dump(merged, sys.stdout, indent=2, ensure_ascii=False)
print()
" "${ZSH_OUT}" "${SKHD_OUT}" "${WEZ_OUT}" "${NVIM_OUT}" >"${MERGED_OUT}"

if [[ -n "${OUT_PATH}" ]]; then
    mkdir -p "$(dirname "${OUT_PATH}")"
    cp "${MERGED_OUT}" "${OUT_PATH}"
else
    cat "${MERGED_OUT}"
fi

success "keybinding extraction complete"
