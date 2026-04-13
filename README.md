# dotfiles

macOS / Linux / WSL 用。
Windows は [dotfiles-win](https://github.com/bigdra50/dotfiles-win) を参照。

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap | bash
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
./scripts/install-tools.sh        # update tools
```

## Docs

- [Bark通知セットアップ](docs/bark-notification.md) - Claude Code → iPhone プッシュ通知
