{ pkgs, ... }:
# 現行 .config/mise/config.toml の常用 CLI を nixpkgs パッケージへマッピングする。
#
# 対象外（意図的に除外）:
#   - 言語ランタイム（node/go/rust/python/ruby/bun/deno/java/julia）
#     → プロジェクト単位のバージョン切替は mise / nix devShell の領分。
#   - GUI / macOS 専用（wezterm, yabai, skhd, フォント）→ hosts/mac.nix と nix-darwin の領分。
#   - nixpkgs 未収録（cargo:mcat 等）→ overlay か mise 併用が必要。
#
# 属性名がバイナリ名と異なるものはコメントで明示する。
{
  home.packages = with pkgs; [
    # --- ファイル / 検索 ---
    bat
    fd
    ripgrep # rg
    fzf
    jq
    gron
    dust # du-dust から改名済み（バイナリも dust）
    duf
    bottom # バイナリは btm
    lsd
    glow
    yazi

    # --- ナビゲーション / シェル UX ---
    zoxide
    starship
    atuin
    carapace

    # --- diff / git ---
    delta
    difftastic # バイナリは difft
    lazygit
    gh
    ghq

    # --- 開発ユーティリティ ---
    just
    direnv
    hyperfine
    hexyl
    xh
    gum
    tokei
    onefetch
    procs

    # --- lint / format（CI と共通のサブセット）---
    shellcheck
    shfmt
    actionlint
    stylua

    # --- エディタ ---
    neovim
  ];
}
