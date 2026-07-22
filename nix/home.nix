{
  config,
  lib,
  ...
}:
{
  imports = [
    ./modules/packages.nix
    ./modules/shell.nix
    ./modules/programs.nix
  ];

  # 既存 dotfiles リポジトリの絶対パス。
  # modules/shell.nix が mkOutOfStoreSymlink の参照元として使う。
  # store へコピーせず「生きた symlink」を張るので、リポジトリ側の編集が即反映される
  # （= symlinks.sh と同じ挙動）。
  options.dotfiles.root = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/dev/github.com/bigdra50/dotfiles";
    description = "既存 dotfiles リポジトリの絶対パス";
  };

  config = {
    programs.home-manager.enable = true;

    # 初回導入時の Home Manager 状態バージョン。以後は据え置く。
    home.stateVersion = "24.05";
  };
}
