# dotfiles

## 導入

### ワンライナーインストール（推奨）

新しいマシンで最も簡単な方法：

**macOS / Linux / WSL:**
```bash
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap.ps1 | iex
```

このコマンドは以下を自動的に実行します：
1. プラットフォーム検出 (macOS/Linux/WSL/Windows)
2. gitのインストール（必要な場合）
3. dotfilesリポジトリのクローン
4. ツールのインストールとシンボリックリンクの作成

#### カスタムディレクトリを指定する場合

**macOS / Linux / WSL:**
```bash
DOTFILES_DIR=$HOME/custom/path curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap | bash
```

**Windows (PowerShell):**
```powershell
$env:DOTFILES_DIR='C:\custom\path'; irm https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap.ps1 | iex
```

### 手動インストール

すでにgitがインストールされている場合：

**macOS / Linux / WSL:**
```bash
# リポジトリをクローン
git clone https://github.com/bigdra50/dotfiles.git ~/dev/github.com/bigdra50/dotfiles
cd ~/dev/github.com/bigdra50/dotfiles

# インストール実行
./install.sh

# 非インタラクティブモード
INTERACTIVE=false ./install.sh
```

**Windows (PowerShell):**
```powershell
# リポジトリをクローン
git clone https://github.com/bigdra50/dotfiles.git ~\dev\github.com\bigdra50\dotfiles
cd ~\dev\github.com\bigdra50\dotfiles

# インストール実行（管理者権限推奨）
.\install.ps1

# 非インタラクティブモード
$env:INTERACTIVE='false'; .\install.ps1
```

## Docker環境でのテスト

```bash
# containerを起動してセットアップ実行
docker-compose up -d ubuntu-dotfiles
docker exec -e INTERACTIVE=false dotfiles-ubuntu /bin/bash -c "
  cd ~/dev/github.com/bigdra50/dotfiles &&
  ./install.sh
"

# containerに接続
docker exec -it dotfiles-ubuntu /bin/zsh
```

## 主要コマンド

### インストール

**macOS / Linux / WSL:**
```bash
# インタラクティブインストール
./install.sh

# 非インタラクティブインストール（自動承認）
INTERACTIVE=false ./install.sh

# カスタムディレクトリ指定
DOTFILES_DIR=~/custom/path ./install.sh

# ヘルプ表示
./install.sh --help
```

**Windows (PowerShell):**
```powershell
# インタラクティブインストール（管理者権限推奨）
.\install.ps1

# 非インタラクティブインストール
$env:INTERACTIVE='false'; .\install.ps1
# or
.\install.ps1 -NonInteractive

# カスタムディレクトリ指定
$env:DOTFILES_DIR='C:\custom\path'; .\install.ps1

# ヘルプ表示
.\install.ps1 -Help
```

### ツール管理

**macOS / Linux / WSL:**
```bash
# 開発ツールのインストール/更新
./scripts/install-tools.sh
```

**Windows (PowerShell):**
```powershell
# 開発ツールのインストール/更新
.\scripts\Install-Tools.ps1
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

bootstrap/install.shが自動的にインストールします：

- `mise` (runtime manager)
- `starship` (prompt)
- Rust/Go/Node.js (mise経由)
- 各種CLI開発ツール（bat, eza, ripgrep等）

### 対応プラットフォーム

- **macOS** (Intel & Apple Silicon)
- **Linux** (Ubuntu/Debian, Fedora, Arch Linux)
- **WSL** (Windows Subsystem for Linux)
- **Windows** (PowerShell 5.1+, Scoop package manager)

## 機能

### マルチプラットフォーム対応

- プラットフォーム自動検出
- パッケージマネージャー抽象化（Homebrew/apt/dnf/pacman/Scoop）
- WSL特有の設定サポート
- ネットワークエラー時の自動リトライ（指数バックオフ、bootstrap時）
- シンプルなBashスクリプトベース（外部依存なし）
- Windows: PowerShellスクリプト、Scoop統合、シンボリックリンクサポート

## 注意事項

- デフォルトでリポジトリは `~/dev/github.com/bigdra50/dotfiles` に配置されます
  - Windows: `%USERPROFILE%\dev\github.com\bigdra50\dotfiles`
- 既存ファイルはインストール時に自動的にバックアップされます（`.backup.YYYYMMDD_HHMMSS`）
- `INTERACTIVE=false`でCI/自動環境に対応しています
- インストール後は以下でシェルを再起動してください：
  - macOS/Linux: `source ~/.zshrc`
  - Windows: `. $PROFILE`

### Windows固有の注意事項

- シンボリックリンク作成のため、**管理者権限での実行を推奨**します
- Developer Modeを有効にすると、管理者権限なしでもシンボリックリンクが作成可能です
  - 設定 → 更新とセキュリティ → 開発者向け → 開発者モード
- Scoopパッケージマネージャーが自動的にインストールされます

