# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Neovim設定ファイル。lazy.nvimによるプラグイン管理、LSP/補完/デバッグ機能を備えた開発環境。

## Commands

```bash
# ヘルスチェック
nvim --headless "+checkhealth" +q

# プラグイン更新
nvim --headless "+Lazy sync" +q

# LSPツールのインストール
nvim --headless "+MasonUpdate" +q

# 設定の文法チェック
nvim --headless -u init.lua +q
```

## Architecture

### 起動フロー

```
init.lua
  ├── ~/.vimrc (互換性のため読み込み、termencodingは除外)
  ├── lua/base.lua (基本設定、キーマップ、Leader=Space)
  └── lua/config/lazy.lua
        └── lua/plugins/*.lua (プラグイン定義)
              ├── ui.lua      - カラースキーム、Snacks.nvim、Oil、ステータスライン
              ├── lsp.lua     - Mason、LSP、Formatter、Linter、補完
              ├── editor.lua  - Treesitter、Telescope、Git統合、デバッグ
              ├── ai.lua      - AI関連（現在無効）
              └── go.lua      - Go固有設定
```

### プラグイン設定の二層構造

- `lua/plugins/*.lua`: lazy.nvimプラグイン定義（依存関係、遅延読み込み条件）
- `after/plugin/*.rc.lua`: プラグイン読み込み後の詳細設定（キーマップ、オプション）
- `plugin/*.lua`: 起動時に読み込む設定（lspconfig, lspsaga）

### ユーティリティモジュール (`lua/utils/`)

| モジュール | 用途 |
|-----------|------|
| `path.lua` | クロスプラットフォームパス操作、ツール検索、Homebrew/Xcodeパス取得 |
| `keymap.lua` | キーマップ設定ヘルパー（`bulk_set`で一括設定可能） |
| `plugin.lua` | `safe_require`でプラグイン読み込み（存在しない場合はnil返却） |
| `autocmd.lua` | 自動コマンド設定 |
| `signs.lua` | 診断・DAPサイン設定 |

### LSP構成

Mason経由で自動インストール（`mason-tool-installer`で管理）:
- `gopls`, `pyright`, `bash-language-server`, `netcoredbg`
- Roslyn LSP（C#/Razor）: seblyng/roslyn.nvim
- sourcekit-lsp: Swift用（visionOSシミュレータ対応コメントアウト有）
- UPM LSP: Unityパッケージマニフェスト用カスタムLSP

フォーマッタ設定（conform.nvim、保存時自動実行）:
- Go: goimports → gofmt
- Python: ruff_format → ruff_organize_imports
- C#: csharpier（`~/.dotnet/tools/csharpier`）
- Swift: swiftformat

### 主要キーバインド

| キー | 機能 | 定義場所 |
|------|------|----------|
| `<Space>` | Leader | base.lua |
| `gd`, `<C-]>` | 定義へジャンプ | lspsaga.rc.lua |
| `gf` | 参照検索（Lspsaga finder） | lspsaga.rc.lua |
| `K` | ホバードキュメント | lspsaga.rc.lua |
| `rn` | リネーム | lspsaga.rc.lua |
| `g[`, `g]` | 前後の診断へ移動 | lspsaga.rc.lua |
| `<leader>ff` | ファイル検索 | telescope.rc.lua |
| `<leader>fg` | grep検索 | telescope.rc.lua |
| `<leader>i` | inlay hints切り替え | lspconfig.lua |
| `-` | 親ディレクトリ（Oil） | ui.lua |
| `F1` | init.luaを開く | base.lua |
| `jj` | Escapeへマップ（挿入モード） | base.lua |

デバッグ関連（nvim-dap + xcodebuild.nvim）:

| キー | 機能 |
|------|------|
| `<leader>dd` | ビルド＆デバッグ |
| `<leader>dc` | 続行 |
| `<leader>ds` | ステップオーバー |
| `<leader>di` | ステップイン |
| `<leader>do` | ステップアウト |
| `<leader>b` | ブレークポイント切り替え |

### 特記事項

- Neovim 0.12+の非推奨API警告は`vim.deprecate`で抑制中
- `vim.tbl_flatten`警告も`vim.notify`で抑制中
- Masonツールは24時間間隔で自動更新
- Python環境: `~/.venvs/nvim/bin/python`を優先、なければuvプロジェクト
- Snacks.nvim: dashboard、picker、notifier、image preview（wezterm）等を統合
- Goファイルはinlay hintsがデフォルト有効
