# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

個人用dotfilesリポジトリ。シンボリックリンクベースで設定ファイルを管理。

- リポジトリ: `~/dev/github.com/bigdra50/dotfiles`
- 対応OS: macOS, Linux, WSL
- Windows は [dotfiles-win](https://github.com/bigdra50/dotfiles-win) で管理

## Key Commands

```bash
# フルセットアップ（mise task経由）
mise run setup                      # 全ステップ実行
mise run setup:symlinks             # シンボリンクのみ
mise run setup:claude               # Claude設定のみ
./install.sh                        # シム（mise run setup へ委譲）
./install.sh --only symlinks,claude # 特定ステップのみ

# 新規マシンセットアップ（ワンライナー）
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/master/bootstrap | bash
```

## Architecture

### Zsh設定 (`.config/zsh/` = `$ZDOTDIR`)

ロード順序:
1. `~/.zshenv` - ZDOTDIR設定のみ → `$ZDOTDIR/.zshenv` に委譲
2. `$ZDOTDIR/.zshenv` - PATH、環境変数、XDG設定
3. `$ZDOTDIR/.zshrc` - 以下を順にロード:
   - `environment.zsh` - mise有効化、Go設定、atuin初期化
   - `interface.zsh` - Starship、viバインディング
   - `extensions.zsh` - プラグインロード
   - `.zshrc_local` - ローカルオーバーライド

### ツール管理・セットアップ

| ファイル | 用途 |
|---------|------|
| `mise.toml` | セットアップタスク定義（`setup:*`） |
| `.config/mise/config.toml` | グローバルツール定義（ランタイム + CLI） |
| `tools.toml` | プラットフォーム固有ツール（brew/apt） |
| `scripts/setup/*.sh` | 各タスクのbash実装 |

miseがオーケストレーター。

mise 活用パターン:
- `MISE_ENV=staging mise run deploy` — 環境プロファイル切り替え（`.mise.staging.toml`）
- `mise lock` — ツールバージョンをチェックサム付きでロック
- `mise prepare` — lockfile変更を検知して依存インストールを自動実行
- hk（git hookマネージャ） — `.hk.toml` or `.mise.toml` 内でフック定義

### シンボリンク対象

| ソース | リンク先 |
|--------|----------|
| `.*` (ルート) | `~/.*` |
| `.config/*` | `~/.config/*` |
| `.claude/` | `~/.claude/` |

Zsh設定は `.config/zsh/` に統合。`ZDOTDIR=$XDG_CONFIG_HOME/zsh` で参照。

プラットフォーム固有の除外:
- Linux/WSL: `.yabairc`, `.skhdrc`（macOS専用）

### ローカルオーバーライド

マシン固有の設定は以下に記述（gitignore済み）:
- `$ZDOTDIR/.zshrc_local` (`~/.config/zsh/.zshrc_local`)
- `$ZDOTDIR/.zshenv_local` (`~/.config/zsh/.zshenv_local`)
- `~/.gitconfig_local`


## Claude Code設定 (`.claude/`)

```
.claude/
├── agents/         # サブエージェント定義
├── commands/       # カスタムスラッシュコマンド
├── hooks/          # フックスクリプト
├── output-styles/  # 出力スタイル
├── rules/          # コーディングルール（言語別）
├── scripts/        # hooks/skills が参照する補助スクリプト（セッションID解決等）
├── tools/          # 補助スクリプト（statusline 用）
├── settings.json
└── statusline.sh
```

セットアップは `mise run setup:claude`（`scripts/setup/claude.sh`）で実行。
skills は [bigdra50/skills](https://github.com/bigdra50/skills) で管理し、セットアップ時に `npx skills add` で `~/.claude/skills` へ展開する（このリポジトリには置かない）。
