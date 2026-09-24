#!/usr/bin/env bash
# Markdown の文体検査。mise task (md:lint)、CI、.claude/hooks/textlint-*.sh の
# 三者がここを通ることで、手元と CI で同じ結果になるようにする。
#
# Usage:
#   scripts/md-lint.sh                  # 追跡している *.md を全部見る
#   scripts/md-lint.sh path/to/file.md  # 指定ファイルだけ見る (hook 用)
#
# 環境変数:
#   MD_LINT_FORMAT   textlint の formatter (既定 stylish、hook は compact)
#
# 依存は .claude/package.json に置き `npm ci --prefix .claude` で
# .claude/node_modules へ入る。textlint はルール preset を Node の module 解決で
# 引くため、`mise x npm:textlint@latest --` のような ad-hoc 実行では preset を
# 解決できず "No rules found" (exit 1) になる。project-local install が前提。
#
# textlint が自動で読む .textlintignore は cwd のものだけで、設定ファイルの隣は
# 見ない。除外を .claude/ に置いているので --ignore-path で明示的に渡す。
set -uo pipefail

REPO_ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEXTLINT="$REPO_ROOT/.claude/node_modules/.bin/textlint"
CONFIG="$REPO_ROOT/.claude/.textlintrc.json"
IGNORE="$REPO_ROOT/.claude/.textlintignore"
SEMBR="$REPO_ROOT/scripts/sembr-check.sh"
FORMAT="${MD_LINT_FORMAT:-stylish}"

if [[ ! -x "$TEXTLINT" ]]; then
    echo "textlint not installed. Run: npm ci --prefix '$REPO_ROOT/.claude' --ignore-scripts" >&2
    exit 2
fi

# textlint の --fix 案内だけを落とす。指摘そのものは 1 行も削らない。
drop_fix_hint() {
    grep -v -e 'fixable problems\?\.' -e 'Try to run: \$ textlint --fix' || true
}

status=0

if [[ $# -gt 0 ]]; then
    # 除外パターンは textlint の cwd を基準に解決される。hook は任意の
    # ディレクトリから起動されるので、対象を絶対パスに直してから cwd を
    # リポジトリルートへ固定する。リポジトリ外のファイルはどの除外にも
    # 一致しないので、そのまま全ルールが適用される。
    targets=()
    for arg in "$@"; do
        case "$arg" in
            /*) targets+=("$arg") ;;
            *) targets+=("$PWD/$arg") ;;
        esac
    done
    cd "$REPO_ROOT" || exit 2
    # stylish 形式は末尾に "Try to run: $ textlint --fix" を出す。prh の置換候補は
    # リライト方針のヒントであって置換文字列ではないため、--fix は文章を壊す。
    # 案内が読み手（人・モデル）へ届かないよう落とす。
    "$TEXTLINT" -c "$CONFIG" --ignore-path "$IGNORE" -f "$FORMAT" "${targets[@]}" | drop_fix_hint || status=1
    "$SEMBR" "${targets[@]}" || status=1
    exit "$status"
fi

cd "$REPO_ROOT" || exit 2
git ls-files -z -- '*.md' |
    xargs -0 -r "$TEXTLINT" -c "$CONFIG" --ignore-path "$IGNORE" -f "$FORMAT" | drop_fix_hint || status=1
# 一文一行は .textlintignore の除外を受けない。箇条書きの体裁が意図的な
# エージェント向け文書でも、句点で改行する規範は同じように適用されるため。
git ls-files -z -- '*.md' | xargs -0 -r "$SEMBR" || status=1
exit "$status"
