# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

個人用dotfilesリポジトリ。シンボリックリンクベースで設定ファイルを管理。

- リポジトリ: `~/dev/github.com/bigdra50/dotfiles`
- 対応OS: macOS, Linux, WSL, Windows (PowerShell)

## Key Commands

```bash
# インストール
./install.sh                      # インタラクティブ
INTERACTIVE=false ./install.sh    # 非インタラクティブ（CI用）

# ツール更新
./scripts/install-tools.sh

# 新規マシンセットアップ（ワンライナー）
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap | bash

# Windows
irm https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap.ps1 | iex
```

## Architecture

### Zsh設定 (`.zsh/`)

ロード順序:
1. `.zshenv` - PATH、環境変数
2. `.zshrc` - 以下を順にロード:
   - `environment.zsh` - mise有効化、Go設定
   - `interface.zsh` - Starship、viバインディング
   - `extensions.zsh` - プラグインロード
   - `.zshrc_local` - ローカルオーバーライド

### ツール管理

| ファイル | 用途 |
|---------|------|
| `mise/config.toml` | ランタイム管理（go, rust, node, python, neovim等） |
| `tools.toml` | Cargo/Go/プラットフォーム固有ツール |

miseがプライマリのツール管理。`tools.toml`は補助的に使用。

### シンボリンク対象

| ソース | リンク先 |
|--------|----------|
| `.*` (ルート) | `~/.*` |
| `.config/*` | `~/.config/*` |
| `.zsh/` | `~/.zsh/` |
| `.claude/` | `~/.claude/` |

プラットフォーム固有の除外:
- Linux/WSL: `.yabairc`, `.skhdrc`（macOS専用）

### ローカルオーバーライド

マシン固有の設定は以下に記述（gitignore済み）:
- `~/.zshrc_local`
- `~/.zshenv_local`
- `~/.gitconfig_local`

## ツール監査

```bash
./scripts/audit-tools.sh  # 手動実行
```

miseで管理すべきツールが他の場所（brew, cargo, npm -g, pipx）にインストールされていないかチェック。
シェル起動時に週1回自動実行される（`.zsh/plugins/audit-tools.zsh`）。

許可リスト（`scripts/audit-tools.sh`内で定義）:
- brew: python, ruby（他パッケージの依存関係）
- npm: MCP関連ツール
- pipx: 特殊用途ツール

## Claude Code設定 (`.claude/`)

```
.claude/
├── commands/   # カスタムスラッシュコマンド
├── docs/       # ドキュメント
├── rules/      # コーディングルール（言語別）
├── settings.json
├── skills/     # スキル定義（フラット構造必須）
└── install.sh  # ~/.claude へのシンボリンク作成
```
