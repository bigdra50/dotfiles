#!/usr/bin/env bash
# Stop hook: 作業完了時、cwd の implementation-notes.html が
# 前回開いた版より新しければ既定アプリで1回だけ開く（macOS/Linux/Windows 対応）。
# 更新がなければ何もしない（毎ターン開かないための重複抑制）。
set -u

input="$(cat)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
[ -z "$cwd" ] && cwd="$PWD"

f="$cwd/implementation-notes.html"
[ -f "$f" ] || exit 0

# ファイル mtime（GNU stat -c / BSD stat -f の両対応）
file_mtime() {
    stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null
}

# 既定アプリで開く（プラットフォーム別）。IMPL_NOTES_OPEN_CMD で明示上書き可。
open_file() {
    local target="$1"
    if [ -n "${IMPL_NOTES_OPEN_CMD:-}" ]; then
        "$IMPL_NOTES_OPEN_CMD" "$target" >/dev/null 2>&1
        return
    fi
    case "$(uname -s)" in
        Darwin*) open "$target" >/dev/null 2>&1 ;;
        Linux*) xdg-open "$target" >/dev/null 2>&1 ;;
        MINGW* | MSYS* | CYGWIN*)
            local win
            win="$(cygpath -w "$target" 2>/dev/null || printf '%s' "$target")"
            # パスは env 経由で渡す（クォート/アポストロフィ事故回避）。single-quote で powershell に $env: を素通しさせる。
            IMPL_NOTES_WIN_PATH="$win" powershell.exe -NoProfile -Command 'Start-Process -FilePath $env:IMPL_NOTES_WIN_PATH' >/dev/null 2>&1 ||
                cmd.exe //c start "" "$win" >/dev/null 2>&1
            ;;
        *) return 1 ;;
    esac
}

cur="$(file_mtime "$f")"
[ -z "$cur" ] && exit 0
key="$(printf '%s' "$f" | { shasum 2>/dev/null || sha1sum 2>/dev/null; } | cut -d' ' -f1)"
[ -z "$key" ] && exit 0
marker="${TMPDIR:-/tmp}/claude-impl-notes-${key}"
prev="$(cat "$marker" 2>/dev/null || echo '')"

if [ "$cur" != "$prev" ]; then
    printf '%s' "$cur" >"$marker"
    open_file "$f" || true
fi
exit 0
