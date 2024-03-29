#!/usr/bin/env just --justfile

default:
  @echo "no default task"

# home-manager apply
home-manager: 
  #!/usr/bin/env bash
  home-manager switch -I localconfig=$HOME/dotfiles/nix-home/machine/$(hostname).nix

  # home-manager install
home-manager-install:
  #!/usr/bin/env bash
  . $HOME/.nix-profile/etc/profile.d/nix.sh
  export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
  nix-shell '<home-manager>' -A install

# nix-env install
nix-install:
  #!/usr/bin/env bash
  #mkdir -p ~/.config
  ln -sf ~/dotfiles/dot_config ~/.config

  if [[ $(uname -s) == "Darwin" ]]; then
    sh <(curl -L https://nixos.org/nix/install) 
  else
    sh <(curl -L https://nixos.org/nix/install) --no-daemon
  fi

  source ~/.nix-profile/etc/profile.d/nix.sh
  nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update

# nix-cleanup
nix-cleanup:
  #!/usr/bin/env bash
  rm -rf $HOME/{.nix-channels,.nix-defexpr,.nix-profile,.config/nixpkgs}
  sudo rm -rf /nix

# darwin apply
nix-darwin:
  #!/usr/bin/env bash
  darwin-rebuild switch

# nix-darwin install
nix-darwin-install:
  #!/usr/bin/env bash
  mkdir -p $HOME/.nixpkgs
  ln -s $HOME/dotfiles/nix-darwin/darwin-configuration.nix $HOME/.nixpkgs/darwin-configuration.nix
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
  ./result/bin/darwin-installer

# nix-darwin update
nix-darwin-update:
  #!/usr/bin/env bash
  nix-channel --update darwin
  darwin-rebuild changelog

# switch all
switch: nix-darwin home-manager
