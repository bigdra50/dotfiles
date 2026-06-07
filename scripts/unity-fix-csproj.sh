#!/usr/bin/env bash
# unity-fix-csproj.sh
#
# Unity プロジェクトの .csproj が参照する Unity バージョンがインストールされていない場合、
# インストール済みのバージョンに HintPath を書き換える。
# .csproj は gitignore 済み前提。Unity Editor で開き直せば正しいパスで再生成される。
#
# Usage:
#   unity-fix-csproj.sh [project-dir] [fallback-version]

set -euo pipefail

UNITY_BASE="/Applications/Unity/Hub/Editor"
PROJECT_DIR="${1:-.}"

# Unity プロジェクトか判定
VERSION_FILE="$PROJECT_DIR/ProjectSettings/ProjectVersion.txt"
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Not a Unity project (ProjectSettings/ProjectVersion.txt not found)" >&2
    exit 1
fi

# プロジェクトの Unity バージョンを取得
PROJECT_VERSION=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+[a-z][0-9]+' "$VERSION_FILE" | head -1)
if [[ -z "$PROJECT_VERSION" ]]; then
    echo "Could not parse Unity version from $VERSION_FILE" >&2
    exit 1
fi

# インストール済みか確認
if [[ -d "$UNITY_BASE/$PROJECT_VERSION" ]]; then
    exit 0
fi

# .csproj が存在するか
csproj_count=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.csproj" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$csproj_count" -eq 0 ]]; then
    exit 0
fi

# csproj から実際に参照されているパスパターンを取得（最初の HintPath から）
HINT_SUBPATH=$(grep -m1 "HintPath.*$PROJECT_VERSION" "$PROJECT_DIR"/*.csproj 2>/dev/null |
    sed "s|.*$UNITY_BASE/$PROJECT_VERSION/||" | sed 's|/[^/]*\.dll.*||' | head -1)

# フォールバック先の決定
find_fallback() {
    local specified="$1"
    if [[ -n "$specified" && -d "$UNITY_BASE/$specified" ]]; then
        echo "$specified"
        return
    fi

    # インストール済みバージョンから、同じパス構造を持つものを新しい順に探す
    for ver_dir in $(ls -1d "$UNITY_BASE"/*/ 2>/dev/null | sort -V -r); do
        local ver
        ver=$(basename "$ver_dir")
        [[ "$ver" == "$PROJECT_VERSION" ]] && continue
        # csproj の HintPath と同じディレクトリ構造が存在するか確認
        if [[ -n "$HINT_SUBPATH" && -d "$ver_dir/$HINT_SUBPATH" ]]; then
            echo "$ver"
            return
        fi
    done
}

FALLBACK=$(find_fallback "${2:-}")

if [[ -z "$FALLBACK" ]]; then
    echo "No compatible Unity version found for fallback." >&2
    exit 1
fi

echo "Unity $PROJECT_VERSION not installed, falling back to $FALLBACK"

# 置換実行
patched=0
for f in "$PROJECT_DIR"/*.csproj; do
    [[ -f "$f" ]] || continue
    if grep -q "$PROJECT_VERSION" "$f"; then
        sed -i '' "s|$PROJECT_VERSION|$FALLBACK|g" "$f"
        patched=$((patched + 1))
    fi
done

echo "Patched $patched .csproj files"
