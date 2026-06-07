# Reference Hub

このリポジトリの設定から、検索可能なリファレンスを自動生成するパイプライン。
1つの検索UI（チップフィルタ + インクリメンタル検索）を共有する4ドメインを持つ。

| ドメイン | 内容 | ソース |
| -------- | ---- | ------ |
| keybindings | WezTerm / Zsh / skhd / Neovim のキーバインド | `.wezterm.lua`, `.config/zsh`, `.skhdrc`, `.config/nvim` |
| shortcuts | alias / zsh-abbr / 関数 | `.config/zsh` |
| tasks | mise タスクカタログ | `mise tasks --json` |
| claude | skill / agent / command / rule | `.claude/` |

## 参照方法

| 経路 | 用途 |
| ---- | ---- |
| GitHub Pages | <https://bigdra50.github.io/dotfiles/> がハブ。各ドメインは `/<domain>/`（master push で自動更新） |
| `mise run keys` | keybindings を fzf で即引き（ローカルキャッシュ、`KEYS_REFRESH=1` で強制再生成） |

## アーキテクチャ

```
各ドメインのソース ──> extract_<domain>(.py|.sh) ──> ドメイン別 JSON
                                                        |
                                  共通レンダラ (common/, 列駆動)
                                                        |
                          ┌──────────────────┬──────────────────┐
                          v                  v                  v
                   <domain>/index.html   hub index.html   TSV (fzf)
```

`scripts/reference/` の構成:

- `common/` — ドメイン非依存の純粋関数: `page_config`（PageConfig/Column/Filter/NavLink）、`render_html`（列駆動の検索可能HTML）、`render_tsv`、`hub_html`、`nav`
- `keybindings/` `shortcuts/` `tasks/` `claude/` — 各ドメインのパーサ + `page.py`（`PAGE_CONFIG` / `TSV_FIELDS` / `build_meta`）
- ルートの `extract_*.py` / `extract.sh` / `render.py` / `render_hub.py` / `build_site.sh` / `validate.py` / `search.sh` — I/O境界（CLI）

パース・diff・レンダリングはすべて純粋関数（Python 3.14 標準ライブラリのみ）。プロセス起動とファイルI/OはCLIラッパとbashに分離（Functional Core, Imperative Shell）。

新ドメインの追加は「`<domain>/` パッケージ + `page.py` + `extract_<domain>` を足す」だけ。共通レンダラとCIはそのまま再利用される。

## mise タスク

| タスク | 内容 |
| ------ | ---- |
| `keys` | keybindings を fzf 検索 |
| `keys:build` / `keys:check` / `keys:html` | keybindings の抽出 / 検証 / 単体HTML |
| `ref:html` | ハブ + 全ドメインのサイトを `/tmp/reference-site` に生成 |
| `ref:lint` | ruff + mypy --strict |
| `ref:test` | unittest |

## ドメイン別の要点

- keybindings: `origin`（custom/default、既定フィルタは custom）と `change`（added/overridden/unchanged）でタグ付け。重複判定キー `tool+context+mode+key`。Neovim は v1 では global マップのみ、`<Plug>` は除外。zsh の同義端末シーケンス（`\e[A`/`\eOA`→Up）は集約。
- shortcuts: `kind`（alias/abbr/function）でフィルタ。同名関数（ch, pop 等）は集約せず両方表示し衝突を可視化。
- tasks: `mise tasks --json` を正準ソースに、名前 prefix で category 分類。リポジトリ外のグローバルタスクは `global:<name>` に正規化。
- claude: frontmatter（`description: |` ブロックスカラー対応の自前パーサ）から抽出。frontmatter の無い rule / command は先頭見出しをフォールバック。

## CI（.github/workflows/reference.yml）

- PR: lint → unittest → `build_site.sh`（keybindings 検証込み）でサイト全体を生成
- master push: 上記に加えて GitHub Pages へデプロイ
- wezterm はパーサが `show-keys --lua` の出力フォーマットに依存するためバージョン固定（`WEZTERM_VERSION`）。fixtures が回帰を検出する
- tasks ドメインのため CI に mise を導入し、`XDG_CONFIG_HOME` をリポジトリの `.config` に向けて全タスクを拾う
- 生成物はリポジトリにコミットしない（artifact → Pages のみ）

## GitHub Pages の有効化（初回のみ）

```bash
gh api repos/bigdra50/dotfiles/pages -X POST -f build_type=workflow
```

または Settings → Pages → Build and deployment → Source を `GitHub Actions` に設定。

## ローカルでの検証

```bash
mise run ref:test && mise run ref:lint
mise run ref:html   # /tmp/reference-site/index.html をブラウザで確認
```

## v2 候補

- Neovim の filetype / LspAttach コンテキスト別ダンプ（buffer-local マップ対応）
- 各ドメインの fzf 検索（`search.sh` を domain 引数対応に一般化）
- ツール一覧（`.config/mise/config.toml` / `tools.toml`）ドメインの追加
