# Nix 移行実験（Home Manager）

現行の mise + symlink セットアップを壊さずに、Nix flake + Home Manager で
dotfiles を管理する実現性を検証する実験ディレクトリ。

- 既存の `install.sh` / `mise.toml` / `scripts/setup/*` には一切影響しない。
- ここだけで完結し、失敗しても `nix/` を無視すれば元の運用に戻る。

## 用語

- **Nix**: パッケージをハッシュで固定し再現可能な環境を作るパッケージマネージャ兼ビルドシステム。
- **flake**: inputs を `flake.lock` で固定して再現性を保証する仕組み。
- **Home Manager**: ユーザー環境（パッケージ + dotfiles）を宣言的に管理する Nix モジュール。
  現行の mise（ツール導入）+ `symlinks.sh`（設定リンク）の役割を 1 宣言で担う。
- **nix-darwin**: macOS のシステム設定（`defaults`、brew cask、サービス）を宣言化する別レイヤ。Home Manager の範囲外。

## 構成

```
nix/
├── flake.nix          # inputs(nixpkgs, home-manager) / outputs(homeConfigurations.{wsl,mac})
├── flake.lock         # `nix flake lock` で生成
├── home.nix           # 共通設定 + dotfiles.root オプション定義
├── modules/
│   ├── packages.nix   # 常用 CLI を nixpkgs へマッピング
│   ├── shell.nix      # .config/* を mkOutOfStoreSymlink で参照
│   └── programs.nix   # direnv をネイティブ宣言管理する例
├── hosts/
│   ├── wsl.nix        # x86_64-linux（Docker 検証もこれ）
│   └── mac.nix        # aarch64-darwin（スケルトン）
├── Dockerfile         # WSL 相当の検証環境
└── verify.sh          # switch + ツール/シンボリンク検証
```

## 使い方

### 前提

Nix（flakes 有効）が入っていること。未導入なら:

```bash
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon   # single-user
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### 適用

`home.username` / `home.homeDirectory` を自分の環境に合わせて `hosts/*.nix` で上書きしてから:

```bash
# WSL / Linux
nix run home-manager/master -- switch --flake ./nix#wsl

# macOS
nix run home-manager/master -- switch --flake ./nix#mac
```

`dotfiles.root`（既定 `~/dev/github.com/bigdra50/dotfiles`）が
このリポジトリの実体を指している必要がある（`home.nix` で上書き可）。

### Docker で検証

```bash
docker build -f nix/Dockerfile -t dotfiles-nix:latest .
docker run --rm dotfiles-nix:latest bash nix/verify.sh
```

## mise ↔ Nix 対応

| 現行 mise の役割 | Nix での担い手 |
| --- | --- |
| CLI ツール導入（`.config/mise/config.toml`） | `modules/packages.nix`（nixpkgs） |
| 設定ファイルの symlink（`symlinks.sh`） | `modules/shell.nix`（`xdg.configFile` + `mkOutOfStoreSymlink`） |
| プログラム設定の生成 | `programs.<name>`（例: `programs.direnv`） |
| 言語ランタイムのプロジェクト単位切替 | **mise 継続** or `nix develop`（devShell） |
| macOS GUI / システム設定 | **nix-darwin**（本実験の範囲外） |

### 対象を絞った理由

- **言語ランタイム（node/go/rust/python…）は対象外**。プロジェクト単位のバージョン切替は
  mise / devShell の領分で、Home Manager のグローバル固定とは目的が異なる。
- **GUI・macOS 専用（wezterm, yabai, skhd, フォント）は対象外**。Home Manager では扱えず nix-darwin が要る。
- **nixpkgs 未収録（`cargo:mcat` 等）は対象外**。overlay 自作か mise 併用が必要。

## 既知の制約・注意

- **Mac 分は Linux 上でビルド検証できない**。`hosts/mac.nix` はスケルトンで、実機での `switch` が必要。
- **フル移行には nix-darwin が必須**。Home Manager 単体では brew cask やシステム `defaults` を管理できない。
- **`programs.<name>` と symlink の二重管理に注意**。同じツールを両方で管理すると衝突する。
  移行フェーズでは片方ずつ置き換える。
- **属性名 ≠ バイナリ名**: `du-dust`→`dust`、`bottom`→`btm`、`difftastic`→`difft`。
