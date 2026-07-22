{ ... }:
# macOS（Apple Silicon）向けプロファイル（aarch64-darwin）。
#
# 位置づけ: Linux 上ではビルド検証できないためスケルトン。
# 実機（Mac）で `home-manager switch --flake ./nix#mac` を回して検証する。
#
# Home Manager が担うのはユーザー環境（CLI パッケージ + dotfiles）まで。
# 以下は Home Manager の範囲外で、フル移行時は nix-darwin が必要:
#   - GUI アプリ（wezterm 等の brew cask）→ nix-darwin の homebrew モジュール
#   - ウィンドウ管理（yabai/skhd）→ nix-darwin の services or brew
#   - システム defaults（キーリピート等）→ nix-darwin の system.defaults
# 詳細は docs/decisions のドラフト参照。
{
  home.username = "bigdra50";
  home.homeDirectory = "/Users/bigdra50";
}
