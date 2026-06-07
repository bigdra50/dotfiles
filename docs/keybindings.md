# Keybindings Pipeline

WezTerm / Zsh / skhd / Neovim に分散したキーバインドを自動解析し、一覧として参照できるようにするパイプライン。

## 参照方法

| 経路 | 用途 |
| ---- | ---- |
| `mise run keys` | ターミナルから fzf で即引き検索（ローカルキャッシュ、初回はやや時間がかかる） |
| GitHub Pages | <https://bigdra50.github.io/dotfiles/> でフィルタ・検索可能なHTML（master push 時に自動更新） |

## アーキテクチャ

```
.wezterm.lua ──┐  wezterm show-keys --lua (effective / -n default) ── diff ──┐
.config/nvim ──┤  nvim --headless "Lazy! load all" / --clean ──────── diff ──┤
.config/zsh ───┤  bindkey 静的パース ────────────────────────────────────────┤
.skhdrc ───────┘  'mod - key : cmd' 静的パース ──────────────────────────────┤
                                                                             v
                          共通JSONスキーマ (tool/context/mode/key/action/
                          description/source/origin/change)
                                                                             |
                          validate.py (スキーマ + 重複 + 件数下限)
                                                                             |
                          ┌──────────────────────┬───────────────────────────┐
                          v                      v                           v
                  render_html.py          render_tsv.py               CI job summary
                  (GitHub Pages)          (mise run keys / fzf)
```

実装は `scripts/keybindings/`。
パース・diff・レンダリングは `scripts/keybindings/keybindings/` パッケージの純粋関数（Python 3.14 標準ライブラリのみ）、プロセス起動とファイルI/OはCLIラッパとbashに分離している。

## mise タスク

| タスク | 内容 |
| ------ | ---- |
| `keys` | fzf 検索（キャッシュが古ければ自動再生成、`KEYS_REFRESH=1` で強制） |
| `keys:build` | 全ツール抽出 → JSON |
| `keys:check` | 抽出 + スキーマ検証 + 重複検出 + 件数下限 |
| `keys:html` | 検索可能HTMLを /tmp に生成 |
| `keys:lint` | ruff + mypy --strict |
| `keys:test` | unittest |

## スキーマの要点

- `origin`: `custom`（自分の設定由来）/ `default`（ツール組み込み）。HTMLの既定フィルタは custom のみ表示
- `change`: `added` / `overridden` / `unchanged`
- 重複判定キー: `tool + context + mode + key`。重複があると `validate.py` が exit 1
- Neovim は v1 では global マップのみ（`coverage: global-only`）。filetype / LspAttach 依存の buffer-local マップは対象外
- `<Plug>` マッピングは除外（ユーザーが押すキーではないため）
- zsh の同義端末シーケンス（`\e[A` / `\eOA` → Up 等）は1レコードに集約

## CI（.github/workflows/keybindings.yml）

- PR: 抽出 → lint → unittest → validate → HTML生成 まで
- master push: 上記に加えて GitHub Pages へデプロイ
- wezterm はパーサが出力フォーマットに依存するためバージョン固定（`WEZTERM_VERSION`）。更新時は fixtures のテストが回帰を検出する
- 生成物はリポジトリにコミットしない（artifact → Pages のみ）

## GitHub Pages の有効化（初回のみ）

```bash
gh api repos/bigdra50/dotfiles/pages -X POST -f build_type=workflow
```

または Settings → Pages → Build and deployment → Source を `GitHub Actions` に設定。

## ローカルでの検証

```bash
mise run keys:test && mise run keys:lint && mise run keys:check
mise run keys:html   # 生成された /tmp/keybindings-site/index.html をブラウザで確認
```

## v2 候補

- Neovim の filetype / LspAttach コンテキスト別ダンプ（buffer-local マップ対応）
- ツール間で正規化したキー表記による横断比較（同じ物理キーの競合検出）
