# Nix 移行の検討（探索フェーズ）

Status: Exploration（実験段階。最終決定ではない）

## 背景

現行 dotfiles は mise をオーケストレーターに、CLI/ランタイム導入と設定 symlink を
bash スクリプト（`scripts/setup/*`）で行っている。
再現性・宣言性を高める選択肢として Nix への移行可否を実験で評価する。

想定環境: 主 macOS、副 WSL Ubuntu。

## 選択肢

| 案 | 内容 | ユーザ環境 | システム設定 |
| --- | --- | --- | --- |
| A: 現状維持 | mise + symlink 継続 | mise | bash + brew |
| B: Home Manager | ユーザ環境（CLI + dotfiles）を宣言化。mise の一部を置換 | Nix/HM | brew 継続 |
| C: HM + nix-darwin | Mac のシステム設定まで宣言化する完全移行 | Nix/HM | nix-darwin |

## トレードオフ

**Nix/HM の利点**

- パッケージをハッシュで固定 → マシン間・時間軸で完全再現。`flake.lock` で pin。
- 導入と設定リンクを 1 つの宣言（`home-manager switch`）に統合。symlink スクリプト不要。
- ロールバック可能（世代管理）。壊れたら前の世代へ即戻せる。

**Nix/HM のコスト**

- 学習コスト（Nix 言語、モジュールシステム）。
- ランタイムのプロジェクト単位バージョン切替は HM の不得手領域 → mise / devShell 併用が現実的。
- nixpkgs 未収録ツール（`cargo:mcat` 等）は overlay 自作か mise 併用が必要。
- Mac の GUI（brew cask）・システム `defaults`・yabai/skhd は HM 単体では扱えず nix-darwin が要る（案 C）。

## 実験で確認したこと（Linux x86_64 / Nix 2.24.9）

`nix/` に flake + Home Manager 構成を作り、`hosts/wsl` プロファイルを実ビルドして確認した。

- flake が評価でき、inputs（nixpkgs + home-manager、`follows` 連携）が正しく解決する。
- `homeConfigurations.wsl.activationPackage` が cache.nixos.org からの取得を経て**最後までビルドできる**
  （neovim 0.12.4, yazi, actionlint ほか。所要 ~24s）。
- ビルド生成物に**現行 mise の常用 CLI が実バイナリとして揃う**（home-path に 52 バイナリ。
  bat/fd/rg/fzf/jq/dust/btm/lsd/glow/zoxide/starship/atuin/delta/difft/lazygit/gh/ghq/just/
  direnv/nvim/yazi/gum/tokei/procs/shellcheck/shfmt/actionlint/stylua ほか）。
  ビルド済みバイナリの実行も確認（bat 0.26.1 / starship 1.26.0 / ripgrep 15.2.0）。
- `mkOutOfStoreSymlink` による dotfiles リンクが宣言通り生成される
  （`.config/{zsh,starship.toml,atuin,git,lazygit,glow}` + `programs.direnv` の `.config/direnv`）。
- `hosts/mac`（aarch64-darwin）も評価は通る（クロス評価で derivation 生成を確認）。

要修正だった差分: `du-dust` は nixpkgs で `dust` へ改名済み（属性名のみ変更、バイナリは `dust`）。

未確認:

- `home-manager switch` の実適用（実ホームへの symlink 生成・PATH 反映）。
  ビルドまでは通っており、残るは活性化のみ。検証用 Docker 構成（`nix/Dockerfile` + `verify.sh`）と
  CI テンプレート（`nix/ci/nix-ci.yml` を `.github/workflows/` へ配置）で end-to-end を回す。
- Mac（aarch64-darwin）の**ビルド**（評価は通るがビルドは Mac 実機が要る）。`hosts/mac.nix` はスケルトン。

## 判断材料と推奨

- **Home Manager は現行 mise の「CLI 導入 + 設定リンク」を置き換えられる**見込みが立った。
- ただし**ランタイムのプロジェクト単位切替は mise を残す**のが現実的（役割分担）。
- **Mac のフル宣言化には nix-darwin が別途必要**（案 C）。ここは実機での追加検証が要る。

次アクション:

- [ ] 実機（Mac / WSL）で `home-manager switch` を試し、symlink・PATH の実挙動を確認する
- [ ] `flake.lock` を GitHub access のある環境で生成し pin する
- [ ] nix-darwin のスパイクを別途起こし、brew cask / defaults / yabai の宣言化可否を測る
- [ ] mise と HM の役割分担（ランタイム=mise、CLI+dotfiles=HM）で段階移行するかを決める

構成・使い方の詳細は [nix/README.md](../../nix/README.md) を参照。
