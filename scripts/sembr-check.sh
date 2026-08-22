#!/usr/bin/env bash
# 一文一行チェック（.claude/rules/writing-style.md「句点（。）またはピリオド（.）の
# 後で改行する」）。
#
# textlint-rule-one-sentence-per-line を使わない理由:
#   (1) 箇条書き項目にも発火する。規範は「箇条書きの各項目も1行にする」であり、
#       項目内に二文あっても1行に保つのが正しいので衝突する
#   (2) 違反行ではなく段落の先頭行を報告する。行番号をモデルへ差し戻す hook では
#       誤った箇所を指してしまう
#   textlint-filter-rule-node-types で ListItem を除外する案もあるが、フィルタは
#   ルール単位に効かず period-in-list-item まで同時に無効化されるため両立しない。
#
# 判定対象は地の文のみ。frontmatter・コードフェンス・見出し・箇条書き・表・引用は
# 除外する。frontmatter の description は1行に収める形式上の要請があるため対象外。
# 句点の直後が閉じ括弧の場合は引用中の文末なので違反としない。
#
# Usage: scripts/sembr-check.sh <file.md>...
# 終了コード: 違反ありで 1、なしで 0
set -u

status=0
for f in "$@"; do
    if [[ ! -f "$f" ]]; then
        continue
    fi
    out=$(awk -v FN="$f" '
        NR == 1 && /^---[[:space:]]*$/ { fm = 1; next }
        fm { if ($0 ~ /^(---|\.\.\.)[[:space:]]*$/) fm = 0; next }
        /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
        fence { next }
        /^[[:space:]]*#/                   { next }
        /^[[:space:]]*[-*+][[:space:]]/    { next }
        /^[[:space:]]*[0-9]+\.[[:space:]]/ { next }
        /^[[:space:]]*\|/                  { next }
        /^[[:space:]]*>/                   { next }
        /^[[:space:]]*$/                   { next }
        {
            line = $0
            # インラインコードは検査対象外。`periodMarks: ["。"]` のように
            # コード断片が句点を含むと、地の文の一文一行違反と区別が付かない。
            gsub(/`[^`]*`/, "", line)
            gsub(/。[」』）\)]/, "", line)
            if (match(line, /。.*[^[:space:]]/))
                printf "%s:%d: 句点の後で改行する（一文一行）: %s\n", FN, NR, $0
        }
    ' "$f")
    if [[ -n "$out" ]]; then
        printf '%s\n' "$out"
        status=1
    fi
done
exit "$status"
