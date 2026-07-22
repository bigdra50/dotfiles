{ ... }:
# Home Manager が「設定ファイルを symlink する」のではなく
# 「プログラム設定を宣言から生成する」ネイティブ管理の例。
#
# 実験方針: 既存の .config/* は shell.nix で symlink（現行資産を壊さない）。
# 一方このファイルでは、Nix ワークフローで恩恵の大きい direnv だけをネイティブ管理し、
# 「宣言 → 設定生成」の書き味を比較できるようにする。
#
# git / starship / atuin なども programs.<name> で宣言化できるが、
# その場合は shell.nix 側の対応 symlink を外して二重管理を避ける必要がある
# （移行フェーズで段階的に置き換える想定。README 参照）。
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true; # `use flake` を高速化する direnv 拡張
  };
}
