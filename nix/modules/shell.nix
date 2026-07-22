{ config, ... }:
# 既存 .config/* を Home Manager 経由で symlink する。
#
# mkOutOfStoreSymlink を使い、Nix store へコピーせずリポジトリ実体を直接指す。
# これにより symlinks.sh と同じく「リポジトリを編集 → 即反映」が成立し、
# 実験中に既存運用と挙動が乖離しない。
let
  repo = config.dotfiles.root;
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";
in
{
  # ~/.config/<name> -> <repo>/.config/<name>
  xdg.configFile = {
    "zsh".source = link ".config/zsh";
    "starship.toml".source = link ".config/starship.toml";
    "atuin".source = link ".config/atuin";
    "git".source = link ".config/git";
    "lazygit".source = link ".config/lazygit";
    "glow".source = link ".config/glow";
  };

  # ZDOTDIR を既存構成（$XDG_CONFIG_HOME/zsh）に合わせる。
  home.sessionVariables = {
    ZDOTDIR = "${config.xdg.configHome}/zsh";
  };
}
