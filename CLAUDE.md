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
2. `$ZDOTDIR/.zshenv` (全 zsh) - XDG設定、FPATH → `env.zsh` + `func-core.zsh` → `.zshenv_local`
   - `env.zsh` - 正準PATH順序 (mise shims 静的prepend)、GOPATH 等の常時 export
   - `func-core.zsh` - 非対話でも必要な関数 (gh のアカウント自動選択)
3. `$ZDOTDIR/.zprofile` (login) - path_helper が PATH を再構成した後に `env.zsh` を再 source
4. `$ZDOTDIR/.zshrc` (対話のみ) - 以下を順にロード:
   - `interface.zsh` - compinit、atuin、Starship、viバインディング
   - `extensions.zsh` - プラグインロード
   - `.zshrc_local` - ローカルオーバーライド

非対話シェル (スクリプト、Claude Code のツールシェル等) は 1-3 のみ通るため、
PATH・環境変数・常時関数は `.zshrc` チェーンではなく `env.zsh` / `func-core.zsh` に置く。

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
| `.ssh/config` | `~/.ssh/config` (config のみ。鍵は管理しない) |

Zsh設定は `.config/zsh/` に統合。`ZDOTDIR=$XDG_CONFIG_HOME/zsh` で参照。

プラットフォーム固有の除外:
- Linux/WSL: `.yabairc`, `.skhdrc`（macOS専用）

### ローカルオーバーライド

マシン固有の設定は以下に記述（gitignore済み）:
- `$ZDOTDIR/.zshrc_local` (`~/.config/zsh/.zshrc_local`)
- `$ZDOTDIR/.zshenv_local` (`~/.config/zsh/.zshenv_local`) — 秘密情報はここに限る
- `~/.ssh/config.d/local.conf` — マシン固有 ssh ホスト

プロファイル固有の設定（`~/.gitconfig_local`、`~/.gitconfig-<profile>`、`~/.ssh/config.d/<profile>.conf`）は
この repo では管理せず、別の private な dotfiles の setup.sh が配備する。
この repo は汎用フック（`[include]`、`Include config.d/*.conf`、`GH_ORG_CONFIG` 参照）だけを持ち、
固有識別子の混入は `.gitleaks.toml` の custom rules が commit 時に遮断する。


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

skills は [bigdra50/skills](https://github.com/bigdra50/skills) と [bigdra50/unity-cli](https://github.com/bigdra50/unity-cli) で管理し、このリポジトリには置かない。
導入は apm（[Microsoft Agent Package Manager](https://github.com/microsoft/apm)）で行う。宣言的マニフェスト `.apm/apm.yml` に各スキルを `<owner/repo>/<skill-dir>` のサブパスで列挙し（リポジトリ直下は apm パッケージではないため個別のスキルフォルダを指す）、`scripts/setup/claude.sh` が apm を `~/.local`（sudo 不要）へ導入したうえで `apm install -g` でユーザスコープ `~/.claude/skills` へ展開する。
スキルの追加・削除は `.apm/apm.yml` を編集して `mise run setup:claude` で反映し、最新追従は `apm update -g`。旧 `npx skills`（skillpm）状態が残っている場合はセットアップ時に自動でバックアップ退避して apm へ移行する。

settings.json だけは symlink ではなく **jq マージ適用**（`apply_claude_settings`）。
Claude Code が実行時に atomic write で保存するため symlink は保存のたびに実ファイル化して乖離する。
dotfiles 版が定義するキーは dotfiles が勝ち、live 側だけにあるランタイムキーは保持される。
設定を恒久変更するときは dotfiles 側を編集して `mise run setup:claude` で適用する。
