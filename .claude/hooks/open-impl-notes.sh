#!/usr/bin/env bash
# Stop hook: 作業完了時、cwd の implementation-notes.html が
# 前回開いた版より新しければ既定ブラウザで1回だけ開く。
# 更新がなければ何もしない（毎ターン開かないための重複抑制）。
set -u

OPEN_CMD="${IMPL_NOTES_OPEN_CMD:-open}"

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$cwd" ] && cwd="$PWD"

f="$cwd/implementation-notes.html"
[ -f "$f" ] || exit 0

cur="$(stat -f %m "$f" 2>/dev/null)" || exit 0
key="$(printf '%s' "$f" | shasum 2>/dev/null | cut -d' ' -f1)"
marker="${TMPDIR:-/tmp}/claude-impl-notes-${key}"
prev="$(cat "$marker" 2>/dev/null || echo '')"

if [ "$cur" != "$prev" ]; then
  printf '%s' "$cur" >"$marker"
  "$OPEN_CMD" "$f" >/dev/null 2>&1 || true
fi
exit 0
