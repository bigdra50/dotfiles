#!/bin/bash
# PreToolUse hook (matcher: "Bash"): gh の Issue / PR 本文を投稿前に検査する。
#
# 検査するのは --body-file がリテラルで指す実在ファイルだけ。インライン --body の
# 本文をシェル文字列から取り出すのは、クォート・heredoc・変数展開・サブシェルが
# 絡んで安定しない（`gh -R owner/repo` で素通り、`(cd /tmp && gh ...)` で閉じ括弧が
# 本文に混ざることを実測で確認）。取り出せない形は deny せず通す。
# gate ではなく nudge として使い、「本文は .md に書いて --body-file で渡す」規約と
# 組み合わせる。取りこぼしはサーバ側の body-lint workflow が拾う。
#
# textlint-md.sh と違い、プロジェクト自前の .textlintrc* には譲らない。これは意図的。
# repo の .textlintrc はその repo の「ファイル」を統べる設定であって、GitHub 上の
# Issue / PR 本文までは管轄しない。本文は repo の成果物ではなく書き手の文章なので、
# どの repo で書いても個人の規範を当てる。
# 誤爆の risk は実測で低い。英語の本文は prh 辞書も ja-technical-writing も日本語を
# 狙うためほぼ素通りし、通常の日本語の本文も指摘ゼロだった。加えてフェイルオープンかつ
# 2 回で打ち切るので、gate ではなく nudge として働く。
#
# 安全弁:
#   1. deny は 1 セッションあたり CLAUDE_TEXTLINT_MAX_BLOCKS 回まで（既定 2）
#   2. ランナーと textlint 本体のどちらかが無ければフェイルオープン（exit 0）
#   3. CLAUDE_TEXTLINT_DISABLE=1 で無効化
set -uo pipefail

INPUT=$(cat)

if [[ "${CLAUDE_TEXTLINT_DISABLE:-0}" == "1" ]]; then
    exit 0
fi
DENY_LIMIT="${CLAUDE_TEXTLINT_MAX_BLOCKS:-2}"

HOOK_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 0
REPO_ROOT="$(cd -P "$HOOK_DIR/../.." && pwd)" || exit 0
RUNNER="$REPO_ROOT/scripts/md-lint.sh"
# textlint 本体の有無まで見る。ランナーの存在だけで判定すると、依存を入れて
# いないマシンで「検査できていないのに deny する」経路ができる。
if [[ ! -x "$RUNNER" || ! -x "$REPO_ROOT/.claude/node_modules/.bin/textlint" ]]; then
    exit 0
fi

CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [[ -z "$CMD" || -z "$SESSION_ID" ]]; then
    exit 0
fi
case "$SESSION_ID" in
    */*) exit 0 ;;
esac
if [[ ! "$CMD" =~ (^|[[:space:]/])gh[[:space:]] ]]; then
    exit 0
fi
if [[ ! "$CMD" =~ [[:space:]](issue|pr)[[:space:]]+(create|edit|comment)([[:space:]]|$) ]]; then
    exit 0
fi

# --body-file の値だけを拾う。-F は `gh api` では --field を意味するので見ない。
FILES=$(printf '%s' "$CMD" | awk '{
    for (i = 1; i <= NF; i++) {
        if ($i == "--body-file" && i < NF) {
            print $(i + 1)
            i++
        } else if ($i ~ /^--body-file=/) {
            v = $i
            sub(/^--body-file=/, "", v)
            print v
        }
    }
}')

FINDINGS=""
while IFS= read -r raw; do
    if [[ -z "$raw" ]]; then
        continue
    fi
    p="$raw"
    p="${p%\"}"
    p="${p#\"}"
    p="${p%\'}"
    p="${p#\'}"
    # 変数展開・コマンド置換・stdin は解決できない。検査せず通す。
    case "$p" in
        *'$'* | *'`'* | '-') continue ;;
    esac
    case "$p" in
        /*) ;;
        *) p="${HOOK_CWD:-$PWD}/$p" ;;
    esac
    if [[ ! -f "$p" ]]; then
        continue
    fi
    out=$(MD_LINT_FORMAT=compact "$RUNNER" "$p" 2>/dev/null)
    if [[ -n "$out" ]]; then
        FINDINGS="${FINDINGS}${out}"$'\n'
    fi
done <<EOF
$FILES
EOF

if [[ -z "$FINDINGS" ]]; then
    exit 0
fi

COUNTER_DIR="${TMPDIR:-/tmp}/claude-textlint/$SESSION_ID"
mkdir -p "$COUNTER_DIR" 2>/dev/null || exit 0
COUNTER="$COUNTER_DIR/gh-body"
COUNT=$(cat "$COUNTER" 2>/dev/null || echo 0)
if [[ ! "$COUNT" =~ ^[0-9]+$ ]]; then
    COUNT=0
fi
if [[ "$COUNT" -ge "$DENY_LIMIT" ]]; then
    exit 0
fi
printf '%s\n' "$((COUNT + 1))" >"$COUNTER" 2>/dev/null || true

REASON="textlint が Issue / PR の本文ファイルに指摘を出しました。gh は実行していません。
本文を直してから同じコマンドをやり直してください（差し戻しは 1 セッションにつき ${DENY_LIMIT} 回で打ち切ります）。

$FINDINGS"

jq -n --arg reason "$REASON" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
    }
}'
exit 0
