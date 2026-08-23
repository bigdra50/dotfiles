#!/bin/bash
# Stop hook: 指摘が残ったままターンを終えるのを防ぐ最後の関門。
#
# PostToolUse の textlint-md.sh は書き込み単位で差し戻すが、同一ファイルにつき
# 既定 2 回で打ち切る。打ち切られた後も指摘は残るので、ターンの終わりにもう一度
# 見る。検査対象は textlint-md.sh がセッション単位で記録したパスだけで、
# リポジトリ全体は走査しない。記録が無ければ即 exit 0 なので、md を触らない
# セッションでは何もしない。
#
# 検出も判定も既存の scripts/md-lint.sh へ委譲する。textlint の設定・除外・
# 一文一行チェックを二重に持たないため、ここには検査ロジックを置かない。
#
# 無限ループは入力 JSON の stop_hook_active で避ける。公式の hooks リファレンス
# によれば、この値は「Stop フックの結果として Claude Code が既に継続している」
# ことを表す。true なら何もしないので、差し戻しは 1 ターンにつき 1 回で止まる。
# Claude Code 側にも 8 連続 block でターンを終える上限がある。
#
# 安全弁:
#   1. stop_hook_active が true なら何もしない
#   2. ランナーと textlint 本体のどちらかが無ければフェイルオープン（exit 0）
#   3. CLAUDE_TEXTLINT_DISABLE=1 で無効化
#
# 出典の注記: 「AI の変な日本語を Hooks で検査する」という記事が述べる仕様からの
# 推定実装であり、元記事のコードを写したものではない。仕様のうち textlint で
# 表現できる部分は既存の textlint 経路が担い、この hook は Stop での起動点だけを持つ。
set -uo pipefail

# 早期 exit する枝でも stdin は先に読み切る。読まずに抜けると呼び出し側が
# broken pipe を踏む。
INPUT=$(cat)

if [[ "${CLAUDE_TEXTLINT_DISABLE:-0}" == "1" ]]; then
    exit 0
fi

STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
    exit 0
fi

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [[ -z "$SESSION_ID" ]]; then
    exit 0
fi
# session_id は記録のパス片として使うので、区切りを含む値は扱わない
case "$SESSION_ID" in
    */*) exit 0 ;;
esac

TOUCHED="${TMPDIR:-/tmp}/claude-textlint/$SESSION_ID/touched-md"
if [[ ! -s "$TOUCHED" ]]; then
    exit 0
fi

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

# 記録した後に消えたファイルは対象から外す
TARGETS=()
while IFS= read -r recorded; do
    if [[ -n "$recorded" && -f "$recorded" ]]; then
        TARGETS+=("$recorded")
    fi
done <"$TOUCHED"
if [[ ${#TARGETS[@]} -eq 0 ]]; then
    rm -f "$TOUCHED"
    exit 0
fi

RUNNER_STATUS=0
OUTPUT=$(MD_LINT_FORMAT=compact "$RUNNER" "${TARGETS[@]}" 2>/dev/null) || RUNNER_STATUS=$?

if [[ -z "$OUTPUT" ]]; then
    # 正常終了して指摘ゼロなら記録を捨てる。次の Stop は記録なしで即 exit できる。
    # 後で壊れても textlint-md.sh が書き込みのたびに記録し直す。
    # 異常終了（node 不在など）の空出力は「きれい」の根拠にならないので記録は残す。
    if [[ "$RUNNER_STATUS" -eq 0 ]]; then
        rm -f "$TOUCHED"
    fi
    exit 0
fi

REASON="textlint の指摘が残ったまま終わろうとしています。
このセッションで書いた Markdown を直してから終了してください。

直し方: 指摘された語だけを別の語へ差し替えないこと。指摘を含む文を丸ごと書き直す。
多くの指摘は「語が悪い」のではなく「書くべき中身が抜けている」ことを示す。
各指摘の「こう書く:」が書き換え後の形なので、その形へ文ごと寄せる。
textlint --fix は使わないこと。置換候補はリライト方針のヒントであって置換文字列ではない。

指摘が妥当でない場合は直さずに理由を述べてください。

$OUTPUT"

jq -n --arg reason "$REASON" '{decision: "block", reason: $reason}'
exit 0
