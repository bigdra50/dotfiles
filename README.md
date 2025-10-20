# dotfiles

## 導入

### ワンライナーインストール（推奨）

新しいマシンで最も簡単な方法：

```bash
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap | bash
```

このコマンドは以下を自動的に実行します：
1. プラットフォーム検出 (macOS/Linux/WSL)
2. gitのインストール（必要な場合）
3. dotfilesリポジトリのクローン
4. `just`コマンドランナーのインストール
5. ツールのインストールとシンボリックリンクの作成

#### カスタムディレクトリを指定する場合

```bash
DOTFILES_DIR=$HOME/custom/path curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap | bash
```

### 手動インストール

すでにgitとjustがインストールされている場合：

```bash
# リポジトリをクローン
git clone https://github.com/bigdra50/dotfiles.git ~/dev/github.com/bigdra50/dotfiles
cd ~/dev/github.com/bigdra50/dotfiles

# サブモジュールの初期化（Anthropic skills含む）
git submodule update --init --recursive

# インストール実行
just init

# （オプション）スキルのシンボリックリンク作成
just link-skills
```

## Docker環境でのテスト

```bash
# containerを起動してセットアップ実行
docker-compose up -d ubuntu-dotfiles
docker exec -e INTERACTIVE=false dotfiles-ubuntu /bin/bash -c "
  cd ~/.ghq/github.com/bigdra50/dotfiles &&
  just init
"

# containerに接続
docker exec -it dotfiles-ubuntu /bin/zsh
```

## 主要コマンド

### 基本コマンド

```bash
# 利用可能なコマンド表示
just

# 初期セットアップ（ツールインストール + シンボリックリンク作成）
just init

# ツールのインストール/更新のみ
just install-tools

# シンボリックリンク作成のみ
just link

# プラットフォーム情報表示
just info

# 設定を削除（シンボリックリンクを削除）
just unlink
```

### Skills管理コマンド

```bash
# Anthropic skillsサブモジュールを初期化
just init-skills

# スキルを最新バージョンに更新
just update-skills

# ~/.claude/skillsにシンボリックリンクを作成
just link-skills

# スキルの状態とリストを表示
just skills-status
```

### テスト・開発コマンド

```bash
# Dockerコンテナでテスト
just docker-test

# Dockerコンテナのシェルに入る
just docker-shell

# justfileの構文チェック
just validate
```

## カスタマイズ

### ローカル設定の上書き

追跡されないローカル設定ファイルを作成できます：

- `.zshrc_local` - ローカルzsh設定
- `.gitconfig_local` - ローカルgit設定
- `.zshenv_local` - ローカル環境変数

### ツール追加

`tools.toml`を編集して新しいツールを追加：

```toml
[cargo]
tools = [
    { name = "your-tool", version = "latest", description = "ツールの説明" }
]
```

## 必要な環境

### 最小要件（bootstrapが自動処理）

- `curl` または `wget` - bootstrapスクリプトのダウンロードに必要
- `git` - 未インストールの場合は自動的にインストールされます

### 自動インストール

bootstrap/justが自動的にインストールします：

- `just` (command runner)
- `mise` (runtime manager)
- `starship` (prompt)
- Rust/Go/Node.js (mise経由)
- 各種CLI開発ツール（bat, eza, ripgrep等）

### 対応プラットフォーム

- **macOS** (Intel & Apple Silicon)
- **Linux** (Ubuntu/Debian, Fedora, Arch Linux)
- **WSL** (Windows Subsystem for Linux)

## 機能

### マルチプラットフォーム対応

- プラットフォーム自動検出
- パッケージマネージャー抽象化（Homebrew/apt/dnf/pacman）
- WSL特有の設定サポート
- ネットワークエラー時の自動リトライ（指数バックオフ）

### Skills統合

[Anthropic Skills](https://github.com/anthropics/skills)がgitサブモジュールとして統合されています：

```
.claude/skills/
├── anthropics/          # 公式スキル (サブモジュール)
│   ├── mcp-builder/
│   ├── skill-creator/
│   ├── document-skills/
│   └── ...
└── custom/              # カスタムスキル（オプション）
```

詳細は`CLAUDE.md`を参照してください。

## 注意事項

- デフォルトでリポジトリは `~/dev/github.com/bigdra50/dotfiles` に配置されます
- 既存ファイルはインストール時に自動的にバックアップされます（`.backup.YYYYMMDD_HHMMSS`）
- `INTERACTIVE=false`でCI/自動環境に対応しています
- インストール後は`source ~/.zshrc`でシェルを再起動してください

