#!/bin/bash
# PostCompact hook (matcher: ""): 圧縮発生を marker file で記録する。
# PostCompact は additionalContext 出力をサポートしないため、
# context 注入は UserPromptSubmit 側 (userpromptsubmit-compaction-recovery.sh) で行う。
#
# fail-open (常に exit 0)
set -uo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[[ -z "$SESSION_ID" ]] && exit 0
# パス区切りを含む session_id は marker パスとして扱わない
case "$SESSION_ID" in */*) exit 0 ;; esac

# marker file を書く（UserPromptSubmit が検出して context 注入→削除する）
MARKER_DIR="${TMPDIR:-/tmp}/claude-compacted"
mkdir -p "$MARKER_DIR" 2>/dev/null || true
printf '%s\n' "$(date +%s)" >"$MARKER_DIR/$SESSION_ID" 2>/dev/null || true

# compact が実行されたら 60% 警告の未消費 marker と cooldown を両方リセットする
# (未消費の warn marker を残すと、圧縮直後に stale な使用率で通知が誤発火する)
rm -f "${TMPDIR:-/tmp}/claude-compact-warn/$SESSION_ID" 2>/dev/null || true
WARN_DIR="${TMPDIR:-/tmp}/claude-compact-warned"
rm -f "$WARN_DIR/$SESSION_ID" 2>/dev/null || true

exit 0
