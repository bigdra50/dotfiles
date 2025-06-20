# dotfiles

## 導入

### ワンライナーインストール

```bash
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/master/bootstrap | bash
```

### 手動インストール

```bash
# リポジトリをクローン
git clone https://github.com/bigdra50/dotfiles.git ~/dev/github.com/bigdra50/dotfiles
cd ~/dev/github.com/bigdra50/dotfiles

# インストール実行
just init
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

```bash
# 利用可能なコマンド表示
just

# ツールのインストール/更新
just install-tools

# symlink作成
just link

# プラットフォーム情報表示
just info

# Dockerで実行
just docker-test

# 設定を削除
just unlink
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

### 最小要件

- `curl` または `wget`
- `git`

### 自動インストール

他のツールは自動的にインストールされます：

- `just` (command runner)
- `mise` (runtime manager)
- `starship` (prompt)
- 開発用runtimeとツール類

## 注意事項

- リポジトリは `~/dev/github.com/bigdra50/dotfiles` に配置される前提です
- 既存ファイルはインストール時に自動的にbackupされます
- `INTERACTIVE=false`でCI/自動環境に対応しています

