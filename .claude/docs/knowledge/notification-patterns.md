# Claude Code 通知メッセージパターン設計ガイド

---
title: 通知メッセージパターン設計ガイド
version: 1.0.0
last_updated: 2025-07-03
author: Claude Code User
tags: [notification, ui-ux, message-design, claude-code]
---

## 設計原則

### 1. 一目瞭然の原則
- **アイコン**: 操作の種類と結果を視覚的に表現
- **タイトル**: ツール名と結果を簡潔に示す
- **メッセージ**: 必要な情報のみを構造化して表示

### 2. コンテキスト情報の優先順位
1. **操作対象**: ファイル名/コマンド名
2. **操作結果**: 成功/失敗/詳細
3. **プロジェクト情報**: プロジェクト名、ブランチ
4. **時刻**: 操作完了時刻

### 3. 簡潔性と情報量のバランス
- 通知は **3-4行以内** に収める
- 重要な情報を **太字** や **アイコン** で強調
- 長いパスは **相対パス** や **ファイル名** のみ表示

## アイコン体系

### 基本アイコン
| アイコン | 意味 | 使用場面 |
|---------|------|----------|
| ✅ | 成功 | 正常完了した操作 |
| ❌ | 失敗 | エラーが発生した操作 |
| ℹ️ | 情報 | 読み取り、参照操作 |
| 🔍 | 検索 | Glob、Grep操作 |
| 📝 | 編集 | Edit、MultiEdit操作 |
| 📄 | 作成 | Write操作 |
| ⚙️ | 実行 | Bash、コマンド実行 |
| 🔄 | 処理中 | 長時間実行の中間状態 |

### 特殊アイコン
| アイコン | 意味 | 使用場面 |
|---------|------|----------|
| 🎯 | 重要 | 設定ファイル、重要なファイル |
| 🧪 | テスト | テスト関連の操作 |
| 🏗️ | ビルド | ビルド、コンパイル操作 |
| 📦 | パッケージ | package.json等の操作 |
| 🔐 | セキュリティ | 認証、権限関連 |
| ⏱️ | 時間 | 長時間実行の完了 |

## ツール別メッセージパターン

### Write ツール（ファイル作成）

#### 成功パターン
```
タイトル: "Claude Code ✅ ファイル作成"
メッセージ: "ファイル: src/components/Button.tsx
           プロジェクト: my-app (feature/ui)
           時刻: 14:32:15"
```

#### 失敗パターン
```
タイトル: "Claude Code ❌ ファイル作成失敗"
メッセージ: "ファイル: src/components/Button.tsx
           エラー: 権限不足
           時刻: 14:32:15"
```

#### 特殊ケース
```bash
# 設定ファイル
タイトル: "Claude Code 🎯 設定ファイル作成"

# テストファイル
タイトル: "Claude Code 🧪 テストファイル作成"

# 複数ファイル
タイトル: "Claude Code ✅ 複数ファイル作成"
メッセージ: "ファイル: 3個のコンポーネント
           場所: src/components/
           プロジェクト: my-app (feature/ui)"
```

### Edit ツール（ファイル編集）

#### 基本パターン
```
タイトル: "Claude Code ✅ ファイル編集"
メッセージ: "ファイル: package.json
           変更: dependencies追加
           プロジェクト: my-app (main)
           時刻: 14:32:15"
```

#### 大規模変更
```
タイトル: "Claude Code ✅ 大規模編集"
メッセージ: "ファイル: src/utils/helpers.js
           変更: 15箇所のリファクタリング
           プロジェクト: my-app (refactor)
           時刻: 14:32:15"
```

### MultiEdit ツール（一括編集）

```
タイトル: "Claude Code ✅ マルチ編集"
メッセージ: "ファイル: config/settings.json
           変更: 5箇所の設定値更新
           プロジェクト: my-app (config)
           時刻: 14:32:15"
```

### Bash ツール（コマンド実行）

#### 正常終了
```
タイトル: "Claude Code ✅ コマンド実行"
メッセージ: "コマンド: npm test
           結果: 正常終了 (exit 0)
           実行時間: 23秒
           時刻: 14:32:15"
```

#### エラー終了
```
タイトル: "Claude Code ❌ コマンド実行失敗"
メッセージ: "コマンド: npm test
           結果: エラー (exit 1)
           詳細: 3 tests failed
           時刻: 14:32:15"
```

#### 特殊コマンド
```bash
# テスト実行
タイトル: "Claude Code 🧪 テスト実行"

# ビルド実行
タイトル: "Claude Code 🏗️ ビルド実行"

# 長時間実行
タイトル: "Claude Code ⏱️ 長時間実行完了"
メッセージ: "コマンド: npm run build
           実行時間: 2分34秒
           結果: 正常完了"
```

### Read ツール（ファイル読み取り）

```
タイトル: "Claude Code ℹ️ ファイル読み取り"
メッセージ: "ファイル: README.md
           範囲: 全体 (150行)
           プロジェクト: my-app (main)
           時刻: 14:32:15"
```

### Glob/Grep ツール（検索）

#### Glob（ファイル検索）
```
タイトル: "Claude Code 🔍 ファイル検索"
メッセージ: "パターン: **/*.tsx
           結果: 23個のファイル
           場所: src/
           時刻: 14:32:15"
```

#### Grep（文字列検索）
```
タイトル: "Claude Code 🔍 文字列検索"
メッセージ: "パターン: 'useState'
           結果: 8箇所で発見
           対象: *.tsx ファイル
           時刻: 14:32:15"
```

## 動的メッセージ生成

### ファイル種別判定
```bash
get_file_icon() {
    local file_path="$1"
    case "${file_path##*.}" in
        "js"|"jsx"|"ts"|"tsx") echo "📜 JavaScript/TypeScript" ;;
        "py") echo "🐍 Python" ;;
        "json") echo "🎯 設定ファイル" ;;
        "md") echo "📚 ドキュメント" ;;
        "sh") echo "⚙️ シェルスクリプト" ;;
        "test.js"|"spec.js") echo "🧪 テストファイル" ;;
        *) echo "📄 ファイル" ;;
    esac
}
```

### 操作規模判定
```bash
get_operation_scale() {
    local change_count="$1"
    if [ "$change_count" -gt 20 ]; then
        echo "大規模変更"
    elif [ "$change_count" -gt 5 ]; then
        echo "中規模変更"
    else
        echo "変更"
    fi
}
```

### プロジェクト種別判定
```bash
get_project_type() {
    if [ -f "package.json" ]; then
        echo "Node.js"
    elif [ -f "requirements.txt" ]; then
        echo "Python"
    elif [ -f "Cargo.toml" ]; then
        echo "Rust"
    elif [ -f "pom.xml" ]; then
        echo "Java"
    else
        echo ""
    fi
}
```

### コマンド種別判定
```bash
get_command_type() {
    local command="$1"
    case "$command" in
        npm*test*|yarn*test*) echo "🧪 テスト実行" ;;
        npm*build*|yarn*build*) echo "🏗️ ビルド" ;;
        git*) echo "🔄 Git操作" ;;
        *lint*) echo "🔍 コード検査" ;;
        *format*) echo "✨ フォーマット" ;;
        *) echo "⚙️ コマンド実行" ;;
    esac
}
```

## 実装例

### 基本的な通知スクリプト
```bash
#!/bin/bash
# ~/bin/claude-notify.sh

generate_notification() {
    local tool_name="$1"
    local file_path="$2" 
    local success="$3"
    local extra_info="$4"
    
    # アイコンとタイトル生成
    if [ "$success" = "true" ]; then
        case "$tool_name" in
            "Write") title="Claude Code ✅ ファイル作成" ;;
            "Edit") title="Claude Code ✅ ファイル編集" ;;
            "MultiEdit") title="Claude Code ✅ マルチ編集" ;;
            "Bash") title="Claude Code ✅ コマンド実行" ;;
            "Read") title="Claude Code ℹ️ ファイル読み取り" ;;
            "Glob"|"Grep") title="Claude Code 🔍 検索" ;;
            *) title="Claude Code ✅ $tool_name" ;;
        esac
    else
        title="Claude Code ❌ ${tool_name}失敗"
    fi
    
    # メッセージ生成
    local project_name=$(basename "$(pwd)")
    local branch=$(git branch --show-current 2>/dev/null || echo "main")
    local time=$(date '+%H:%M:%S')
    
    if [ -n "$file_path" ] && [ "$file_path" != "null" ]; then
        local relative_path=$(echo "$file_path" | sed "s|$(pwd)/||")
        message="ファイル: $relative_path"
    else
        message="操作: $tool_name"
    fi
    
    message="${message}
プロジェクト: ${project_name} (${branch})
時刻: ${time}"
    
    if [ -n "$extra_info" ]; then
        message="${message}
${extra_info}"
    fi
    
    # 通知送信
    printf '\a'  # WezTerm通知
    osascript -e "display notification \"${message}\" with title \"${title}\"" 2>/dev/null
}
```

## ベストプラクティス

### 1. 情報の優先順位付け
- **最重要**: 操作の成功/失敗
- **重要**: 対象ファイル/コマンド
- **補助**: プロジェクト情報、時刻

### 2. 長い情報の省略
```bash
# ファイルパスの省略
truncate_path() {
    local path="$1"
    local max_length=50
    
    if [ ${#path} -gt $max_length ]; then
        echo "...${path: -$((max_length-3))}"
    else
        echo "$path"
    fi
}
```

### 3. エラー情報の充実
```bash
# エラー時は詳細情報を追加
if [ "$success" = "false" ]; then
    error_detail=$(echo "$input_json" | jq -r '.tool_response.stderr // .tool_response.error // "不明なエラー"')
    extra_info="エラー: $(echo "$error_detail" | head -n 1)"
fi
```

### 4. 通知頻度の制御
```bash
# 同一操作の連続実行を検知
last_notification_file=~/.claude-last-notification
current_hash=$(echo "$tool_name$file_path" | md5sum | cut -d' ' -f1)

if [ -f "$last_notification_file" ]; then
    last_hash=$(cat "$last_notification_file")
    if [ "$current_hash" = "$last_hash" ]; then
        # 重複通知をスキップ
        exit 0
    fi
fi

echo "$current_hash" > "$last_notification_file"
```

## 関連ドキュメント

- [Claude Code Hooks 知識ベース](./claude-code-hooks.md)
- [WezTerm 通知設定](../tools/wezterm-notifications.md)

## 更新履歴

| バージョン | 日付       | 変更内容                    |
| ---------- | ---------- | --------------------------- |
| 1.0.0      | 2025-07-03 | 初版作成、パターン体系化    |