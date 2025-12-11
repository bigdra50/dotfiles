---
allowed-tools: [Read, Write, Edit, Bash, TodoWrite]
argument-hint: <task-name> <command> [--toml]
description: Create mise task with specified name and command for global or project scope
model: haiku
---

# miseタスクを作成

指定した名前とコマンドでmiseタスクを作成し、グローバルまたはプロジェクト固有のタスクとして設定します。

## ワークフロー:

1. **引数の解析**
   - $ARGUMENTSからタスク名とコマンドを抽出
   - スコープ（グローバル/ローカル）の判定

2. **タスクタイプの決定**
   - 引数の形式に基づいてタスクタイプを選択
   - ファイルベース vs TOML設定ベース

3. **ファイルベースタスクの作成**（デフォルト）
   - `~/.config/mise/tasks/` または `.mise/tasks/` にスクリプトファイル作成
   - 実行権限の付与
   - シバン行の自動追加

4. **TOML設定ベースタスクの作成**（--toml指定時）
   - 適切な設定ファイルの特定・読み込み
   - [tasks]セクションへの追加
   - ファイルの更新

5. **作成結果の確認**
   - `mise tasks ls` でタスク一覧を表示
   - 作成したタスクの動作確認

## 引数の形式:

### 基本形式
```
claude /create-mise-task <タスク名> <コマンド> [オプション]
```

### 例:
```bash
# ファイルベースタスク（シェルスクリプト）
claude /create-mise-task "hello" "echo 'Hello World'"

# ファイルベースタスク（Python）
claude /create-mise-task "deploy" "python deploy.py" --lang python

# TOML設定ベースタスク
claude /create-mise-task "build" "npm run build" --toml

# グローバルタスク
claude /create-mise-task "time" "date '+%Y-%m-%d %H:%M:%S'" --global

# ローカルタスク（プロジェクト固有）
claude /create-mise-task "test" "npm test" --local

# 複数行コマンド
claude /create-mise-task "setup" "npm install && npm run build && npm test"
```

## オプション:

### スコープ指定
- `--global`: グローバルタスク（`~/.config/mise/tasks/`）
- `--local`: ローカルタスク（`.mise/tasks/`）
- 未指定: カレントディレクトリに`.mise`が存在すればローカル、なければグローバル

### タスクタイプ
- `--toml`: TOML設定ファイルに記述（デフォルト: ファイルベース）
- `--file`: ファイルベースタスク（デフォルト）

### 言語指定（ファイルベース用）
- `--lang bash`: Bashスクリプト（デフォルト）
- `--lang python`: Pythonスクリプト
- `--lang node`: Node.jsスクリプト
- `--lang ruby`: Rubyスクリプト

### その他
- `--description <説明>`: タスクの説明文
- `--deps <依存タスク>`: 依存するタスクの指定
- `--force`: 既存タスクの上書き

## 自動判定ロジック:

### スコープの自動判定
1. `--global`または`--local`が指定されている場合はそれに従う
2. カレントディレクトリに`.mise`ディレクトリが存在する場合はローカル
3. カレントディレクトリに`mise.toml`または`.mise.toml`が存在する場合はローカル
4. 上記に該当しない場合はグローバル

### 言語の自動判定（ファイルベース）
- コマンドが`python`で始まる場合: Python
- コマンドが`node`で始まる場合: Node.js
- コマンドが`ruby`で始まる場合: Ruby
- その他: Bash（デフォルト）

### シバン行の自動挿入
- Bash: `#!/usr/bin/env bash`
- Python: `#!/usr/bin/env python3`
- Node.js: `#!/usr/bin/env node`
- Ruby: `#!/usr/bin/env ruby`

## ファイル構造の例:

### グローバルタスク
```
~/.config/mise/
├── config.toml
└── tasks/
    ├── hello
    ├── deploy
    └── time
```

### ローカルタスク
```
project-dir/
├── .mise.toml
└── .mise/
    └── tasks/
        ├── test
        ├── build
        └── setup
```

## TOML設定の例:

### シンプルなタスク
```toml
[tasks.build]
run = "npm run build"
description = "Build the project"

[tasks.test]
run = "npm test"
description = "Run tests"
depends = ["build"]
```

### 複雑なタスク
```toml
[tasks.deploy]
run = [
    "npm run build",
    "docker build -t app .",
    "docker push app"
]
description = "Build and deploy application"
depends = ["test"]
sources = ["src/**/*", "package.json"]
outputs = ["dist/**/*"]
```

## エラーハンドリング:

### 入力検証エラー
- **無効なタスク名**: 特殊文字、空文字、予約語のチェック
- **無効なコマンド**: 空文字、危険なコマンドのチェック
- **無効なオプション**: サポートされていないオプションの検出

### ファイル操作エラー
- **ディレクトリ作成失敗**: 権限不足、ディスク容量不足
- **ファイル書き込み失敗**: 権限不足、読み取り専用ファイル
- **設定ファイル解析失敗**: 不正なTOML形式

### 既存タスク重複
- **同名タスクの存在確認**: ユーザーに上書き確認
- **--force オプション**: 強制上書きの実行
- **バックアップ作成**: 上書き前の既存ファイル保護

### mise関連エラー
- **miseコマンド未インストール**: インストール手順の案内
- **設定ファイル不正**: 形式修正の提案
- **タスク実行エラー**: デバッグ情報の提供

## 実行後の確認:

### タスク一覧表示
```bash
# 作成したタスクを含む一覧を表示
mise tasks ls
```

### タスクの実行テスト
```bash
# 作成したタスクを実際に実行
mise run <タスク名>
```

### 設定内容確認
```bash
# TOML設定の場合は設定内容を表示
mise config ls
```

## 使用例の詳細:

### 開発ワークフロー用タスク
```bash
# 開発サーバー起動
claude /create-mise-task "dev" "npm run dev" --description "Start development server"

# テスト実行
claude /create-mise-task "test" "npm test" --deps build --description "Run all tests"

# リント実行
claude /create-mise-task "lint" "npm run lint && npm run type-check" --description "Code quality check"
```

### デプロイ関連タスク
```bash
# ステージング環境デプロイ
claude /create-mise-task "deploy-staging" "scripts/deploy.sh staging" --description "Deploy to staging"

# 本番環境デプロイ
claude /create-mise-task "deploy-prod" "scripts/deploy.sh production" --deps test --description "Deploy to production"
```

### ユーティリティタスク
```bash
# ログ確認
claude /create-mise-task "logs" "tail -f logs/app.log" --description "View application logs"

# データベースマイグレーション
claude /create-mise-task "migrate" "python manage.py migrate" --lang python --description "Run database migrations"
```

$ARGUMENTSが提供された場合、指定されたタスク名とコマンドでmiseタスクを作成します。引数がない場合は対話型モードで詳細な情報収集を行います。