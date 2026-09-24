#!/bin/bash
# PostToolUse hook (matcher: "Write|Edit"): 書き込み直後の Markdown を検査し、
# 指摘があれば decision:"block" + reason でモデルへ差し戻す。
# textlint が決定論的な「検出」、モデルが「修正」を担当する分担。
#
# ユーザスコープ (~/.claude/settings.json) に登録するため、dotfiles 以外の
# プロジェクトでも動く。自前の textlint 設定を持つプロジェクトでは譲る。
# Claude のメモリと scratchpad の md は人が読む文書ではないので検査しない。
#
# 安全弁:
#   1. 同一ファイルへの block は CLAUDE_TEXTLINT_MAX_BLOCKS 回まで（既定 2）。
#      ai-writing preset のルールは textlint --fix で直らないため、直せない指摘で
#      往復し続けるのを防ぐ
#   2. ランナーと textlint 本体のどちらかが無ければフェイルオープン（exit 0）
#   3. CLAUDE_TEXTLINT_DISABLE=1 で無効化
set -uo pipefail

# 早期 exit する枝でも stdin は先に読み切る。読まずに抜けると呼び出し側が
# broken pipe を踏む。
INPUT=$(cat)

if [[ "${CLAUDE_TEXTLINT_DISABLE:-0}" == "1" ]]; then
    exit 0
fi
BLOCK_LIMIT="${CLAUDE_TEXTLINT_MAX_BLOCKS:-2}"

# ~/.claude/hooks は dotfiles へのシンボリックリンクなので、-P で実体を辿ると
# dotfiles のルートに着く。ユーザスコープで起動されても runner を見つけられる。
HOOK_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 0
REPO_ROOT="$(cd -P "$HOOK_DIR/../.." && pwd)" || exit 0
RUNNER="$REPO_ROOT/scripts/md-lint.sh"
# ランナーだけでなく textlint 本体の有無も見る。ランナーは textlint 不在で
# exit 2 を返すので、ここを省くと「検査できていないのに block する」経路ができる。
if [[ ! -x "$RUNNER" || ! -x "$REPO_ROOT/.claude/node_modules/.bin/textlint" ]]; then
    exit 0
fi

FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
HOOK_CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [[ -z "$FILE" || -z "$SESSION_ID" ]]; then
    exit 0
fi
# Windows では file_path がバックスラッシュ区切りで届く
FILE="${FILE//\\//}"
case "$FILE" in
    *.md | *.markdown) ;;
    *) exit 0 ;;
esac
# 人が読む文書ではない 2 か所は検査しない。差し戻しを直す往復が作業を止めるだけになる。
#   - Claude のメモリ（~/.claude/projects/<project>/memory/）: 次のセッションの Claude が読む作業記録
#   - scratchpad（/tmp/claude-<uid>/<project>/<session>/scratchpad/）: セッション限りの一時置き場
case "$FILE" in
    */.claude/projects/*/memory/* | */claude-[0-9]*/scratchpad/*) exit 0 ;;
esac
if [[ ! -f "$FILE" ]]; then
    exit 0
fi
# session_id はカウンタのパス片として使うので、区切りを含む値は扱わない
case "$SESSION_ID" in
    */*) exit 0 ;;
esac

# 自前の textlint 設定を持つプロジェクトでは、そのプロジェクトのルールが正。
# 個人の文体規範を他人のリポジトリへ持ち込まない。CLAUDE_PROJECT_DIR は
# セッション開始時のルートで固定され worktree に追従しないので cwd を使う。
PROJECT_DIR="${HOOK_CWD:-$(dirname "$FILE")}"
if [[ "$PROJECT_DIR" != "$REPO_ROOT" ]]; then
    for cfg in .textlintrc .textlintrc.json .textlintrc.js .textlintrc.yml .textlintrc.yaml; do
        if [[ -f "$PROJECT_DIR/$cfg" ]]; then
            exit 0
        fi
    done
fi

# カウンタの鍵。shasum は perl 同梱で最小構成の Linux に無いことがあるため
# cksum へ落とす。どちらも取れなければ上限を守れないので block しない。
KEY=$(printf '%s' "$FILE" | { shasum 2>/dev/null || cksum 2>/dev/null; } | cut -d' ' -f1)
if [[ -z "$KEY" ]]; then
    exit 0
fi
COUNTER_DIR="${TMPDIR:-/tmp}/claude-textlint/$SESSION_ID"
mkdir -p "$COUNTER_DIR" 2>/dev/null || exit 0
COUNTER="$COUNTER_DIR/$KEY"

OUTPUT=$(MD_LINT_FORMAT=compact "$RUNNER" "$FILE" 2>/dev/null)
if [[ -z "$OUTPUT" ]]; then
    # 直ったら予算を戻す。同じファイルを後で壊したときに再び差し戻せる。
    rm -f "$COUNTER"
    exit 0
fi

COUNT=$(cat "$COUNTER" 2>/dev/null || echo 0)
if [[ ! "$COUNT" =~ ^[0-9]+$ ]]; then
    COUNT=0
fi
if [[ "$COUNT" -ge "$BLOCK_LIMIT" ]]; then
    jq -n --arg f "$FILE" \
        '{systemMessage: ("textlint: " + $f + " に指摘が残っていますが、差し戻し上限に達したため通過させました。")}'
    exit 0
fi
printf '%s\n' "$((COUNT + 1))" >"$COUNTER" 2>/dev/null || true

REASON="textlint が $FILE に指摘を出しました。

直し方: 指摘された語だけを別の語へ差し替えないこと。 指摘を含む文を丸ごと書き直す。
多くの指摘は「語が悪い」のではなく「書くべき中身が抜けている」ことを示す。
たとえば「効く」への指摘は、効果の中身（何が・どれだけ変わるか）が書かれていないという意味なので、
語を言い換えても解決しない。各指摘の「こう書く:」が書き換え後の形を示しているので、その形へ文ごと寄せる。
textlint --fix は使わないこと。prh の置換候補はリライト方針のヒントであって置換文字列ではない。

指摘が妥当でない場合は直さずに理由を述べてください（差し戻しは同一ファイルにつき ${BLOCK_LIMIT} 回で打ち切ります）。

$OUTPUT"

jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
exit 0
