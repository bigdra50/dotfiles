# dotfiles

## Install

```bash
# macOS / Linux / WSL
curl -fsSL https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap | bash

# Windows (PowerShell)
irm https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap.ps1 | iex
```

Manual:

```bash
git clone https://github.com/bigdra50/dotfiles.git ~/dev/github.com/bigdra50/dotfiles
cd ~/dev/github.com/bigdra50/dotfiles
./install.sh  # Windows: .\install.ps1
```

## Commands

```bash
./install.sh                      # install
INTERACTIVE=false ./install.sh    # non-interactive
./scripts/install-tools.sh        # update tools
```
