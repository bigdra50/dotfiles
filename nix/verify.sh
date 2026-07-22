#!/usr/bin/env bash
# Nix 移行実験の検証スクリプト。
# nix/Dockerfile のコンテナ内で実行する想定:
#   docker run --rm dotfiles-nix:latest bash nix/verify.sh
#
# 手順: flake 評価チェック → home-manager switch → ツール/シンボリンク検証。
set -uo pipefail

# --- Nix を PATH に載せる（single-user install）---
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

section() { printf '\n=== %s ===\n' "$1"; }

section "nix flake check (eval only)"
nix flake check ./nix --no-build 2>&1 | tail -n 20 || true

section "home-manager switch --flake ./nix#wsl"
if ! nix run home-manager/master -- switch --flake ./nix#wsl -b bak; then
    echo "FATAL: home-manager switch failed" >&2
    exit 1
fi

# --- switch 後: HM プロファイルを PATH に載せる ---
if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi
export PATH="$HOME/.nix-profile/bin:$PATH"

fail=0

section "verify tools on PATH"
# 属性名≠バイナリ名のものは実バイナリ名で確認する（dust/btm/difft）。
for t in bat fd rg fzf jq gron dust duf btm lsd glow yazi \
    zoxide starship atuin carapace delta difft lazygit gh ghq \
    just direnv hyperfine hexyl xh gum tokei onefetch procs \
    shellcheck shfmt actionlint stylua nvim; do
    if command -v "$t" >/dev/null 2>&1; then
        printf 'OK   %-12s -> %s\n' "$t" "$(command -v "$t")"
    else
        printf 'MISS %-12s\n' "$t"
        fail=1
    fi
done

section "verify dotfiles symlinks"
for l in "$HOME/.config/zsh" "$HOME/.config/starship.toml" \
    "$HOME/.config/atuin" "$HOME/.config/git" \
    "$HOME/.config/lazygit" "$HOME/.config/glow"; do
    if [ -L "$l" ]; then
        printf 'LINK %-28s -> %s\n' "$l" "$(readlink "$l")"
    else
        printf 'MISS %s\n' "$l"
        fail=1
    fi
done

section "spot-check tool execution"
bat --version || fail=1
rg --version | head -n1 || fail=1
starship --version || fail=1

if [ "$fail" -eq 0 ]; then
    section "RESULT: PASS"
else
    section "RESULT: FAIL"
fi
exit "$fail"
