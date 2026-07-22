{ ... }:
# WSL Ubuntu / Linux 向けプロファイル（x86_64-linux）。
# Docker 検証もこのプロファイルを使う。
#
# username / homeDirectory は実マシンに合わせて上書きする。
# Docker イメージ側は同じ値のユーザーを作成して整合させる（nix/Dockerfile 参照）。
{
  home.username = "bigdra50";
  home.homeDirectory = "/home/bigdra50";

  # WSL 固有設定を足すならここに（例: DISPLAY, wslu 連携など）。
  # 現状の実験では共通設定（home.nix）で十分。
}
