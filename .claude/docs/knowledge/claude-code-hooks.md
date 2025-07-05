# Claude Code Hooks 知識ベース

---
title: Claude Code Hooks 完全ガイド
version: 1.0.0
last_updated: 2025-07-03
author: Claude Code User
tags: [claude-code, hooks, automation, notification]
---

## 概要

Claude Code Hooksは、ツール実行の前後で自動的にカスタムコマンドを実行できる強力な機能です。通知システム、フォーマッター実行、検証処理など、様々な自動化に活用できます。

## Hooksの基本構造

### イベントタイプ

Claude Code Hooksには4つのイベントタイプがあります：

1. **PreToolUse** - ツール実行前
2. **PostToolUse** - ツール実行後（推奨）
3. **Notification** - 通知送信時
4. **Stop** - Claude の応答完了直前

### 設定例

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/bin/claude-notify.sh"
          }
        ]
      }
    ]
  }
}
```

## JSON データ構造

### 共通フィールド

すべてのツールで以下の情報が利用可能：

```json
{
  "session_id": "セッション識別子",
  "transcript_path": "/path/to/transcript.md",
  "tool_name": "実行されたツール名",
  "tool_input": { /* ツール固有の入力 */ },
  "tool_response": {
    "success": true,
    /* ツール固有のレスポンス */
  }
}
```

### ツール別データ構造

#### Write ツール（ファイル作成）

```json
{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "/path/to/new/file.js",
    "content": "ファイル内容"
  },
  "tool_response": {
    "success": true,
    "filePath": "/path/to/new/file.js"
  }
}
```

#### Edit ツール（ファイル編集）

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "/path/to/file.js",
    "old_string": "変更前のテキスト",
    "new_string": "変更後のテキスト",
    "replace_all": false
  },
  "tool_response": {
    "success": true,
    "filePath": "/path/to/file.js"
  }
}
```

#### MultiEdit ツール（一括編集）

```json
{
  "tool_name": "MultiEdit",
  "tool_input": {
    "file_path": "/path/to/file.js",
    "edits": [
      {
        "old_string": "変更前1",
        "new_string": "変更後1"
      },
      {
        "old_string": "変更前2", 
        "new_string": "変更後2"
      }
    ]
  },
  "tool_response": {
    "success": true,
    "filePath": "/path/to/file.js"
  }
}
```

#### Bash ツール（コマンド実行）

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test",
    "description": "Run tests",
    "timeout": 120000
  },
  "tool_response": {
    "success": true,
    "stdout": "コマンド出力",
    "stderr": "エラー出力",
    "exit_code": 0
  }
}
```

#### Read ツール（ファイル読み取り）

```json
{
  "tool_name": "Read",
  "tool_input": {
    "file_path": "/path/to/file.md",
    "offset": 1,
    "limit": 100
  },
  "tool_response": {
    "success": true,
    "content": "ファイル内容..."
  }
}
```

#### Glob ツール（ファイル検索）

```json
{
  "tool_name": "Glob",
  "tool_input": {
    "pattern": "**/*.js",
    "path": "/project/src"
  },
  "tool_response": {
    "success": true,
    "matches": [
      "/project/src/index.js",
      "/project/src/utils/helper.js"
    ]
  }
}
```

#### Grep ツール（文字列検索）

```json
{
  "tool_name": "Grep",
  "tool_input": {
    "pattern": "useState",
    "path": "/project/src",
    "include": "*.tsx"
  },
  "tool_response": {
    "success": true,
    "matches": [
      {
        "file": "/project/src/App.tsx",
        "line": 5,
        "content": "const [state, setState] = useState();"
      }
    ]
  }
}
```

## 活用例

### 1. 通知システム

タスク完了時に詳細な通知を送信：

```bash
#!/bin/bash
# ~/bin/claude-notify.sh

input_json=$(cat)

if [ -n "$input_json" ] && command -v jq > /dev/null 2>&1; then
    tool_name=$(echo "$input_json" | jq -r '.tool_name')
    file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // "unknown"')
    success=$(echo "$input_json" | jq -r '.tool_response.success')
    
    # 通知メッセージを構築
    if [ "$success" = "true" ]; then
        title="Claude Code ✅ ${tool_name}"
        message="ファイル: $(basename "$file_path")"
    else
        title="Claude Code ❌ ${tool_name} 失敗"
        message="エラーが発生しました"
    fi
    
    # Wezterm通知
    printf '\a'
    
    # macOS通知
    osascript -e "display notification \"${message}\" with title \"${title}\""
fi
```

### 2. 自動フォーマッター

ファイル編集後に自動的にフォーマッターを実行：

```bash
#!/bin/bash
# ~/bin/auto-format.sh

input_json=$(cat)
file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')

if [ -n "$file_path" ] && [ -f "$file_path" ]; then
    case "$file_path" in
        *.js|*.jsx|*.ts|*.tsx)
            npx prettier --write "$file_path"
            ;;
        *.py)
            black "$file_path"
            ;;
        *.go)
            gofmt -w "$file_path"
            ;;
    esac
fi
```

### 3. Git 自動コミット

特定の操作後に自動的にコミット：

```bash
#!/bin/bash
# ~/bin/auto-commit.sh

input_json=$(cat)
tool_name=$(echo "$input_json" | jq -r '.tool_name')
file_path=$(echo "$input_json" | jq -r '.tool_input.file_path // empty')

if [ "$tool_name" = "Write" ] && [[ "$file_path" == *"config"* ]]; then
    git add "$file_path"
    git commit -m "Auto-commit: Configuration file updated by Claude Code"
fi
```

## ベストプラクティス

### 1. エラーハンドリング

```bash
# JSON解析エラーを適切に処理
if ! echo "$input_json" | jq . >/dev/null 2>&1; then
    echo "Invalid JSON received" >&2
    exit 1
fi
```

### 2. パフォーマンス考慮

```bash
# 重い処理はバックグラウンドで実行
if [ "$file_size" -gt 1000000 ]; then  # 1MB以上
    format_file_async "$file_path" &
else
    format_file "$file_path"
fi
```

### 3. ログ出力

```bash
# デバッグ用ログを残す
echo "$(date '+%Y-%m-%d %H:%M:%S') - [$tool_name] $file_path" >> ~/.claude-hooks.log
```

### 4. 条件分岐

```bash
# プロジェクトタイプに応じた処理
if [ -f "package.json" ]; then
    # Node.js プロジェクト
    npm run lint:fix
elif [ -f "Cargo.toml" ]; then
    # Rust プロジェクト
    cargo fmt
fi
```

## トラブルシューティング

### よくある問題

1. **Hooksが実行されない**
   - `matcher` の設定を確認
   - `PostToolUse` イベントを使用しているか確認
   - スクリプトの実行権限を確認

2. **JSON解析エラー**
   - `jq` がインストールされているか確認
   - stdin からデータが正しく読み込まれているか確認

3. **通知が表示されない**
   - macOS: Script Editor の通知許可を確認
   - WezTerm: `.wezterm.lua` の設定を確認

### デバッグ方法

```bash
# デバッグ用スクリプト
#!/bin/bash
input_json=$(cat)
echo "$input_json" > "/tmp/claude-hooks-debug-$(date +%s).json"
echo "$(date): Hook executed" >> ~/.claude-hooks-debug.log
```

## 関連リソース

- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [参考記事: フォーマッター実行](https://azukiazusa.dev/blog/claude-code-hooks-run-formatter/)
- [WezTerm 通知設定](https://zenn.dev/choplin/articles/cb16c2da711de8)

## 更新履歴

| バージョン | 日付       | 変更内容                  |
| ---------- | ---------- | ------------------------- |
| 1.0.0      | 2025-07-03 | 初版作成、基本機能をまとめ |