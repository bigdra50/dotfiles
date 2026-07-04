# dotfiles

macOS / Linux / WSL 用。
Windows は [dotfiles-win](https://github.com/bigdra50/dotfiles-win) を参照。

キーバインド・エイリアス・mise タスク・Claude 資産の検索可能なリファレンス: <https://bigdra50.github.io/dotfiles/>

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/master/bootstrap | bash
```

Manual:

```bash
git clone https://github.com/bigdra50/dotfiles.git ~/dev/github.com/bigdra50/dotfiles
cd ~/dev/github.com/bigdra50/dotfiles
./install.sh
```

## Commands

```bash
./install.sh                      # install
INTERACTIVE=false ./install.sh    # non-interactive
mise run setup:platform-tools     # update platform tools
```

## Docs

- [architecture](docs/architecture.md) — リポジトリ構成
- [reference](docs/reference.md) — 設定から生成する検索可能リファレンス ([GitHub Pages](https://bigdra50.github.io/dotfiles/))
- [serve-reports](docs/serve-reports.md) — Claude Code レポートの LAN 公開 (`mise run serve-reports`)
