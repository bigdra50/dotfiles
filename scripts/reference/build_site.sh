#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
source scripts/lib.sh

OUT="site"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out)
            OUT="$2"
            shift 2
            ;;
        *)
            error "unknown argument: $1"
            exit 1
            ;;
    esac
done

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

count_json() {
    python3 -c "import json, sys; print(len(json.load(open(sys.argv[1]))))" "$1"
}

render_domain() {
    local domain="$1"
    local json="$2"
    python3 scripts/reference/render.py \
        --domain "${domain}" \
        --input "${json}" \
        --html \
        --out "${OUT}/${domain}/"
}

info "building keybindings..."
bash scripts/reference/extract.sh --out "${WORK}/keybindings.json"
python3 scripts/reference/validate.py --input "${WORK}/keybindings.json"
render_domain keybindings "${WORK}/keybindings.json"
COUNT_KEYBINDINGS="$(count_json "${WORK}/keybindings.json")"

info "building shortcuts..."
python3 scripts/reference/extract_shortcuts.py --root . >"${WORK}/shortcuts.json"
render_domain shortcuts "${WORK}/shortcuts.json"
COUNT_SHORTCUTS="$(count_json "${WORK}/shortcuts.json")"

info "building tasks..."
python3 scripts/reference/extract_tasks.py --root . >"${WORK}/tasks.json"
render_domain tasks "${WORK}/tasks.json"
COUNT_TASKS="$(count_json "${WORK}/tasks.json")"

info "building claude..."
python3 scripts/reference/extract_claude.py --root . >"${WORK}/claude.json"
render_domain claude "${WORK}/claude.json"
COUNT_CLAUDE="$(count_json "${WORK}/claude.json")"

info "building hub..."
COUNTS_JSON="$(python3 -c "import json; print(json.dumps({'keybindings': $COUNT_KEYBINDINGS, 'shortcuts': $COUNT_SHORTCUTS, 'tasks': $COUNT_TASKS, 'claude': $COUNT_CLAUDE}))")"
python3 scripts/reference/render_hub.py --counts "${COUNTS_JSON}" --out "${OUT}/"

success "reference site built at ${OUT}/ (${COUNTS_JSON})"
