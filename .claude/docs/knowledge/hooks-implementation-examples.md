# Claude Code Hooks 実装例とベストプラクティス

---
title: Hooks 実装例とベストプラクティス
version: 1.0.0  
last_updated: 2025-07-03
author: Claude Code User
tags: [implementation, best-practices, examples, claude-code, hooks]
---

## 実装例集

### 1. 基本的な通知システム

#### ファイル: `~/bin/claude-notify.sh`
```bash
#!/bin/bash

# Claude Code 統合通知システム
# 全ツールに対応した詳細通知を提供

main() {
    local input_json=$(cat)
    
    # JSON検証
    if ! validate_json "$input_json"; then
        log_error "Invalid JSON received"
        exit 1
    fi
    
    # 基本情報抽出
    local tool_name=$(echo "$input_json" | jq -r '.tool_name // "unknown"')
    local success=$(echo "$input_json" | jq -r '.tool_response.success // true')
    local session_id=$(echo "$input_json" | jq -r '.session_id // "unknown"')
    
    # ツール別処理
    case "$tool_name" in
        "Write"|"Edit"|"MultiEdit")
            handle_file_operation "$input_json"
            ;;
        "Bash")
            handle_command_execution "$input_json"
            ;;
        "Read"|"Glob"|"Grep")
            handle_read_operation "$input_json"
            ;;
        *)
            handle_generic_operation "$input_json"
            ;;
    esac
    
    # ログ記録
    log_operation "$tool_name" "$success" "$session_id"
}

# JSON検証
validate_json() {
    local json="$1"
    [ -n "$json" ] && echo "$json" | jq . >/dev/null 2>&1
}

# ファイル操作の処理
handle_file_operation() {
    local input_json="$1"
    local tool_name=$(echo "$input_json" | jq -r '.tool_name')
    local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // .tool_response.filePath // "unknown"')
    local success=$(echo "$input_json" | jq -r '.tool_response.success')
    
    # ファイル情報を取得
    local file_info=$(analyze_file "$file_path")
    local operation_detail=$(get_operation_detail "$input_json")
    
    # 通知生成
    local title=$(generate_title "$tool_name" "$success" "$file_info")
    local message=$(generate_file_message "$file_path" "$operation_detail")
    
    send_notification "$title" "$message"
}

# コマンド実行の処理
handle_command_execution() {
    local input_json="$1"
    local command=$(echo "$input_json" | jq -r '.tool_input.command')
    local success=$(echo "$input_json" | jq -r '.tool_response.success')
    local exit_code=$(echo "$input_json" | jq -r '.tool_response.exit_code // 0')
    local execution_time=$(get_execution_time "$input_json")
    
    # コマンド種別判定
    local command_type=$(classify_command "$command")
    
    # 通知生成
    local title="Claude Code $([ "$success" = "true" ] && echo "✅" || echo "❌") $command_type"
    local message="コマンド: $(truncate_text "$command" 40)
結果: $([ "$success" = "true" ] && echo "正常終了" || echo "エラー") (exit $exit_code)"
    
    if [ -n "$execution_time" ]; then
        message="${message}
実行時間: ${execution_time}"
    fi
    
    message="${message}
$(get_project_info)"
    
    send_notification "$title" "$message"
}

# 読み取り操作の処理
handle_read_operation() {
    local input_json="$1"
    local tool_name=$(echo "$input_json" | jq -r '.tool_name')
    local success=$(echo "$input_json" | jq -r '.tool_response.success')
    
    case "$tool_name" in
        "Read")
            local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path')
            local title="Claude Code ℹ️ ファイル読み取り"
            local message="ファイル: $(basename "$file_path")
$(get_project_info)"
            ;;
        "Glob")
            local pattern=$(echo "$input_json" | jq -r '.tool_input.pattern')
            local match_count=$(echo "$input_json" | jq -r '.tool_response.matches | length // 0')
            local title="Claude Code 🔍 ファイル検索"
            local message="パターン: $pattern
結果: ${match_count}個のファイル
$(get_project_info)"
            ;;
        "Grep")
            local pattern=$(echo "$input_json" | jq -r '.tool_input.pattern')
            local match_count=$(echo "$input_json" | jq -r '.tool_response.matches | length // 0')
            local title="Claude Code 🔍 文字列検索"
            local message="パターン: $pattern
結果: ${match_count}箇所で発見
$(get_project_info)"
            ;;
    esac
    
    send_notification "$title" "$message"
}

# ユーティリティ関数群

# ファイル分析
analyze_file() {
    local file_path="$1"
    local extension="${file_path##*.}"
    local size=""
    
    if [ -f "$file_path" ]; then
        size=$(stat -f%z "$file_path" 2>/dev/null || echo "0")
    fi
    
    case "$extension" in
        "js"|"jsx"|"ts"|"tsx") echo "icon:📜 type:JavaScript/TypeScript size:$size" ;;
        "py") echo "icon:🐍 type:Python size:$size" ;;
        "json") echo "icon:🎯 type:設定ファイル size:$size" ;;
        "md") echo "icon:📚 type:ドキュメント size:$size" ;;
        "sh") echo "icon:⚙️ type:シェルスクリプト size:$size" ;;
        *) echo "icon:📄 type:ファイル size:$size" ;;
    esac
}

# コマンド分類
classify_command() {
    local command="$1"
    case "$command" in
        npm*test*|yarn*test*|jest*) echo "🧪 テスト実行" ;;
        npm*build*|yarn*build*|webpack*) echo "🏗️ ビルド" ;;
        git*) echo "🔄 Git操作" ;;
        *lint*|eslint*|tslint*) echo "🔍 コード検査" ;;
        *format*|prettier*) echo "✨ フォーマット" ;;
        npm*install*|yarn*install*) echo "📦 パッケージ管理" ;;
        *) echo "⚙️ コマンド実行" ;;
    esac
}

# プロジェクト情報取得
get_project_info() {
    local project_name=$(basename "$(pwd)")
    local branch=$(git branch --show-current 2>/dev/null || echo "main")
    local time=$(date '+%H:%M:%S')
    
    echo "プロジェクト: ${project_name} (${branch})
時刻: ${time}"
}

# 通知送信
send_notification() {
    local title="$1"
    local message="$2"
    
    # WezTerm通知（bell）
    printf '\a'
    
    # macOS通知
    if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"${message}\" with title \"${title}\" sound name \"Glass\"" 2>/dev/null
    fi
    
    # ログ出力
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [NOTIFICATION] $title" >> ~/.claude-hooks.log
}

# テキスト省略
truncate_text() {
    local text="$1"
    local max_length="$2"
    
    if [ ${#text} -gt $max_length ]; then
        echo "${text:0:$((max_length-3))}..."
    else
        echo "$text"
    fi
}

# エラーログ
log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] $1" >> ~/.claude-hooks-error.log
}

# 操作ログ
log_operation() {
    local tool_name="$1"
    local success="$2"
    local session_id="$3"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [$tool_name] Success:$success Session:$session_id" >> ~/.claude-hooks.log
}

# メイン実行
main "$@"
```

### 2. 自動フォーマッターシステム

#### ファイル: `~/bin/auto-format.sh`
```bash
#!/bin/bash

# Claude Code 自動フォーマッター
# ファイル編集後に自動的にフォーマッターを実行

main() {
    local input_json=$(cat)
    local tool_name=$(echo "$input_json" | jq -r '.tool_name')
    local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')
    local success=$(echo "$input_json" | jq -r '.tool_response.success')
    
    # 成功した編集操作のみ処理
    if [ "$success" = "true" ] && [[ "$tool_name" =~ ^(Write|Edit|MultiEdit)$ ]]; then
        format_file "$file_path"
    fi
    
    # 元の通知スクリプトも実行
    echo "$input_json" | ~/bin/claude-notify.sh
}

# ファイルフォーマット
format_file() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        return 1
    fi
    
    local extension="${file_path##*.}"
    local formatter_used=""
    
    case "$extension" in
        "js"|"jsx"|"ts"|"tsx")
            if command -v prettier >/dev/null 2>&1; then
                prettier --write "$file_path" 2>/dev/null
                formatter_used="Prettier"
            fi
            ;;
        "py")
            if command -v black >/dev/null 2>&1; then
                black "$file_path" 2>/dev/null
                formatter_used="Black"
            elif command -v autopep8 >/dev/null 2>&1; then
                autopep8 --in-place "$file_path" 2>/dev/null
                formatter_used="autopep8"
            fi
            ;;
        "go")
            if command -v gofmt >/dev/null 2>&1; then
                gofmt -w "$file_path" 2>/dev/null
                formatter_used="gofmt"
            fi
            ;;
        "rs")
            if command -v rustfmt >/dev/null 2>&1; then
                rustfmt "$file_path" 2>/dev/null
                formatter_used="rustfmt"
            fi
            ;;
        "json")
            if command -v jq >/dev/null 2>&1; then
                jq . "$file_path" > "${file_path}.tmp" && mv "${file_path}.tmp" "$file_path"
                formatter_used="jq"
            fi
            ;;
    esac
    
    # フォーマット実行をログに記録
    if [ -n "$formatter_used" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [FORMAT] $file_path with $formatter_used" >> ~/.claude-format.log
    fi
}

main "$@"
```

### 3. Git 統合システム

#### ファイル: `~/bin/git-integration.sh`
```bash
#!/bin/bash

# Claude Code Git統合
# 特定の操作後に自動コミットやブランチ操作を実行

main() {
    local input_json=$(cat)
    local tool_name=$(echo "$input_json" | jq -r '.tool_name')
    local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')
    local success=$(echo "$input_json" | jq -r '.tool_response.success')
    
    # Gitリポジトリ内でのみ動作
    if [ ! -d .git ]; then
        # 元の通知スクリプトのみ実行
        echo "$input_json" | ~/bin/claude-notify.sh
        return
    fi
    
    if [ "$success" = "true" ]; then
        case "$tool_name" in
            "Write"|"Edit"|"MultiEdit")
                handle_file_changes "$file_path" "$tool_name"
                ;;
        esac
    fi
    
    # 元の通知スクリプトも実行
    echo "$input_json" | ~/bin/claude-notify.sh
}

# ファイル変更の処理
handle_file_changes() {
    local file_path="$1"
    local tool_name="$2"
    
    # 自動コミット対象のファイルかチェック
    if should_auto_commit "$file_path"; then
        auto_commit "$file_path" "$tool_name"
    fi
    
    # ステージング
    if should_auto_stage "$file_path"; then
        git add "$file_path"
        log_git_operation "staged" "$file_path"
    fi
}

# 自動コミット判定
should_auto_commit() {
    local file_path="$1"
    
    # 設定ファイルは自動コミット
    case "$file_path" in
        *"package.json"|*"package-lock.json"|*"yarn.lock")
            return 0
            ;;
        *"config"*|*".config"*)
            return 0
            ;;
        *"README.md"|*"CHANGELOG.md")
            return 0
            ;;
    esac
    
    return 1
}

# 自動ステージング判定
should_auto_stage() {
    local file_path="$1"
    
    # すべてのファイルを自動ステージング（設定可能）
    return 0
}

# 自動コミット実行
auto_commit() {
    local file_path="$1"
    local tool_name="$2"
    local commit_message=""
    
    case "$tool_name" in
        "Write")
            commit_message="feat: Add $(basename "$file_path")

🤖 Created by Claude Code"
            ;;
        "Edit"|"MultiEdit")
            commit_message="update: Modify $(basename "$file_path")

🤖 Updated by Claude Code"
            ;;
    esac
    
    git add "$file_path"
    git commit -m "$commit_message"
    
    log_git_operation "committed" "$file_path"
}

# Git操作ログ
log_git_operation() {
    local operation="$1"
    local file_path="$2"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [GIT] $operation $file_path" >> ~/.claude-git.log
}

main "$@"
```

### 4. プロジェクト固有の処理

#### ファイル: `~/bin/project-specific.sh`
```bash
#!/bin/bash

# プロジェクト固有の処理
# プロジェクトタイプに応じた自動化を実行

main() {
    local input_json=$(cat)
    local tool_name=$(echo "$input_json" | jq -r '.tool_name')
    local success=$(echo "$input_json" | jq -r '.tool_response.success')
    
    if [ "$success" = "true" ]; then
        local project_type=$(detect_project_type)
        
        case "$project_type" in
            "nodejs")
                handle_nodejs_project "$input_json"
                ;;
            "python")
                handle_python_project "$input_json"
                ;;
            "rust")
                handle_rust_project "$input_json"
                ;;
            "unity")
                handle_unity_project "$input_json"
                ;;
        esac
    fi
    
    # 元の通知スクリプトも実行
    echo "$input_json" | ~/bin/claude-notify.sh
}

# プロジェクトタイプ検出
detect_project_type() {
    if [ -f "package.json" ]; then
        echo "nodejs"
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
        echo "python"
    elif [ -f "Cargo.toml" ]; then
        echo "rust"
    elif [ -f "Assets" ] && [ -d "ProjectSettings" ]; then
        echo "unity"
    else
        echo "generic"
    fi
}

# Node.js プロジェクト処理
handle_nodejs_project() {
    local input_json="$1"
    local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')
    
    case "$file_path" in
        *"package.json")
            # package.json変更時は依存関係を更新
            if command -v npm >/dev/null 2>&1; then
                npm install >/dev/null 2>&1 &
                log_project_operation "nodejs" "npm install triggered"
            fi
            ;;
        *".js"|*".jsx"|*".ts"|*".tsx")
            # TypeScript/JavaScript ファイル変更時の型チェック
            if [ -f "tsconfig.json" ] && command -v tsc >/dev/null 2>&1; then
                tsc --noEmit >/dev/null 2>&1 &
                log_project_operation "nodejs" "type check triggered"
            fi
            ;;
    esac
}

# Python プロジェクト処理
handle_python_project() {
    local input_json="$1"
    local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')
    
    case "$file_path" in
        *"requirements.txt"|*"pyproject.toml")
            # 依存関係ファイル変更時
            log_project_operation "python" "dependencies file changed"
            ;;
        *".py")
            # Python ファイル変更時の構文チェック
            if command -v python >/dev/null 2>&1; then
                python -m py_compile "$file_path" >/dev/null 2>&1
                log_project_operation "python" "syntax check for $file_path"
            fi
            ;;
    esac
}

# Rust プロジェクト処理
handle_rust_project() {
    local input_json="$1"
    local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')
    
    case "$file_path" in
        *"Cargo.toml")
            # Cargo.toml変更時は依存関係を更新
            if command -v cargo >/dev/null 2>&1; then
                cargo check >/dev/null 2>&1 &
                log_project_operation "rust" "cargo check triggered"
            fi
            ;;
        *".rs")
            # Rust ファイル変更時のフォーマットと構文チェック
            if command -v rustfmt >/dev/null 2>&1; then
                rustfmt "$file_path" >/dev/null 2>&1
                log_project_operation "rust" "formatted $file_path"
            fi
            ;;
    esac
}

# Unity プロジェクト処理
handle_unity_project() {
    local input_json="$1"
    local file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')
    
    case "$file_path" in
        *".cs")
            # C# スクリプト変更時の処理
            log_project_operation "unity" "C# script modified: $file_path"
            ;;
        *"ProjectSettings"*)
            # プロジェクト設定変更時
            log_project_operation "unity" "project settings modified"
            ;;
    esac
}

# プロジェクト操作ログ
log_project_operation() {
    local project_type="$1"
    local operation="$2"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [PROJECT:$project_type] $operation" >> ~/.claude-project.log
}

main "$@"
```

## ベストプラクティス

### 1. パフォーマンス最適化

#### 非同期処理
```bash
# 重い処理はバックグラウンドで実行
heavy_operation() {
    local file_path="$1"
    
    # ファイルサイズチェック
    local file_size=$(stat -f%z "$file_path" 2>/dev/null || echo "0")
    
    if [ "$file_size" -gt 1048576 ]; then  # 1MB以上
        # バックグラウンドで実行
        format_large_file "$file_path" &
    else
        # 同期実行
        format_file "$file_path"
    fi
}
```

#### キャッシュ機能
```bash
# 処理結果をキャッシュ
cache_dir=~/.claude-hooks-cache
mkdir -p "$cache_dir"

get_file_info_cached() {
    local file_path="$1"
    local cache_key=$(echo "$file_path" | md5sum | cut -d' ' -f1)
    local cache_file="$cache_dir/$cache_key"
    
    if [ -f "$cache_file" ] && [ "$cache_file" -nt "$file_path" ]; then
        cat "$cache_file"
    else
        analyze_file "$file_path" | tee "$cache_file"
    fi
}
```

### 2. エラーハンドリング

#### 堅牢なエラー処理
```bash
# エラートラップ
set -euo pipefail
trap cleanup EXIT

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Script failed with exit code $exit_code"
    fi
}

# 依存関係チェック
check_dependencies() {
    local required_commands=("jq" "git")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            exit 1
        fi
    done
}
```

### 3. 設定管理

#### 設定ファイルシステム
```bash
# 設定ファイル: ~/.claude-hooks.conf
CONFIG_FILE=~/.claude-hooks.conf

# デフォルト設定
DEFAULT_CONFIG='
{
  "notifications": {
    "enabled": true,
    "sound": true,
    "duration": 5000
  },
  "formatting": {
    "enabled": true,
    "auto_stage": false
  },
  "git": {
    "auto_commit": false,
    "auto_stage": true
  }
}
'

# 設定読み込み
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "$DEFAULT_CONFIG" > "$CONFIG_FILE"
    fi
    
    # 設定を環境変数に読み込み
    eval "$(jq -r 'to_entries | .[] | "export CLAUDE_\(.key | ascii_upcase)=\(.value)"' "$CONFIG_FILE")"
}
```

### 4. テストとデバッグ

#### テスト用スクリプト
```bash
# テスト用のモックデータ生成
generate_test_data() {
    local tool_name="$1"
    local file_path="${2:-/tmp/test.js}"
    
    cat <<EOF
{
  "session_id": "test-session-$(date +%s)",
  "tool_name": "$tool_name",
  "tool_input": {
    "file_path": "$file_path"
  },
  "tool_response": {
    "success": true,
    "filePath": "$file_path"
  }
}
EOF
}

# テスト実行
run_tests() {
    echo "Testing Write operation..."
    generate_test_data "Write" "/tmp/test.js" | ~/bin/claude-notify.sh
    
    echo "Testing Edit operation..."
    generate_test_data "Edit" "/tmp/test.py" | ~/bin/claude-notify.sh
    
    echo "Testing Bash operation..."
    generate_test_data "Bash" | ~/bin/claude-notify.sh
}
```

#### デバッグモード
```bash
# デバッグフラグ
DEBUG=${DEBUG:-false}

debug_log() {
    if [ "$DEBUG" = "true" ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# 詳細ログ出力
if [ "$DEBUG" = "true" ]; then
    set -x  # コマンドをトレース
fi
```

## まとめ

これらの実装例とベストプラクティスを参考に、プロジェクトの要件に応じてClaude Code Hooksをカスタマイズしてください。重要なポイント：

1. **モジュラー設計**: 機能ごとにスクリプトを分割
2. **エラーハンドリング**: 想定外の状況に対する適切な処理
3. **パフォーマンス**: 重い処理の非同期化とキャッシュ
4. **設定管理**: 柔軟な設定システム
5. **ログ出力**: デバッグとモニタリングのための情報記録

## 関連ドキュメント

- [Claude Code Hooks 知識ベース](./claude-code-hooks.md)
- [通知メッセージパターン設計ガイド](./notification-patterns.md)

## 更新履歴

| バージョン | 日付       | 変更内容                      |
| ---------- | ---------- | ----------------------------- |
| 1.0.0      | 2025-07-03 | 初版作成、実装例とベストプラクティス追加 |