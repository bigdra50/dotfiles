# Tool Audit Plugin
# 週1回程度、miseで管理すべきツールの散らかりをチェック

_audit_tools_check() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"
    local last_run_file="$cache_dir/audit-last-run"
    local audit_script="${DOTFILES_DIR:-$HOME/dev/github.com/bigdra50/dotfiles}/scripts/audit-tools.sh"
    local interval_days=7

    # スクリプトが存在しなければスキップ
    [[ ! -x "$audit_script" ]] && return

    # キャッシュディレクトリ作成
    [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"

    # 最終実行日時チェック
    if [[ -f "$last_run_file" ]]; then
        local last_run=$(cat "$last_run_file")
        local now=$(date +%s)
        local diff=$(( (now - last_run) / 86400 ))

        # 指定日数未満ならスキップ
        [[ $diff -lt $interval_days ]] && return
    fi

    # 実行日時を記録
    date +%s > "$last_run_file"

    # バックグラウンドで実行（起動を遅延させない）
    (
        sleep 2  # 少し待ってから実行
        echo ""
        echo "\033[0;36m[Tool Audit] 週次チェックを実行中...\033[0m"
        "$audit_script"
    ) &!
}

# インタラクティブシェルでのみ実行
[[ -o interactive ]] && _audit_tools_check
