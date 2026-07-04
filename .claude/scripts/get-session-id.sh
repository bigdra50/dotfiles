#!/bin/bash
# Claude Code の現行セッションIDを出力する。
# Bash ツール実行時は CLAUDE_CODE_SESSION_ID が設定されている (Claude Code v2.x)。
# 取得できない場合は何も出力せず exit 1（呼び出し側で Hard gate として扱う）。
#
# 前提: この env var と hook stdin JSON の .session_id は同一セッションを指す
# (v2.1.201 で一致を確認済み)。将来のバージョンで意味が変わると
# compact-prep の state file を復旧 hook が見つけられなくなるため、
# 復旧が黙って失敗するようになったらまずここを疑う。
#
# Usage:
#   get-session-id.sh                      # セッションIDのみ出力
#   get-session-id.sh --state-path        # compact-prep state file のフルパスを出力
#   get-session-id.sh --plan-pointer-path # active plan pointer file のフルパスを出力
set -uo pipefail

if [[ -z "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
  exit 1
fi

case "${1:-}" in
  --state-path)
    printf '%s\n' "${TMPDIR:-/tmp}/claude-compact-state/${CLAUDE_CODE_SESSION_ID}.md"
    ;;
  --plan-pointer-path)
    printf '%s\n' "${TMPDIR:-/tmp}/claude-active-plan/${CLAUDE_CODE_SESSION_ID}"
    ;;
  *)
    printf '%s\n' "$CLAUDE_CODE_SESSION_ID"
    ;;
esac
exit 0
