# Nix 移行実験の検証環境（WSL Ubuntu 相当）。
# ubuntu:24.04 に Nix を single-user インストールし、flake + Home Manager を検証する。
# ビルドは Nix 導入までに留め、switch と検証は nix/verify.sh（実行時）に分離する
# （nix 導入レイヤをキャッシュし、検証だけ素早く回すため）。
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl xz-utils git sudo \
    && rm -rf /var/lib/apt/lists/*

# wsl.nix プロファイルの username / homeDirectory に整合させる。
RUN useradd -m -s /bin/bash -u 1000 bigdra50 \
    && echo "bigdra50 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER bigdra50
ENV USER=bigdra50 HOME=/home/bigdra50

# Nix を single-user モードで導入（Docker では daemon/systemd 不要で最も素直）。
RUN curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh \
    && sh /tmp/nix-install.sh --no-daemon \
    && rm /tmp/nix-install.sh

# flake / nix-command を有効化。
RUN mkdir -p "$HOME/.config/nix" \
    && printf 'experimental-features = nix-command flakes\n' > "$HOME/.config/nix/nix.conf"

# 既存 dotfiles を「CLAUDE.md が定める既定パス」へ配置する
# （nix/home.nix の dotfiles.root 既定値と一致 = mkOutOfStoreSymlink の参照先）。
COPY --chown=bigdra50:bigdra50 . /home/bigdra50/dev/github.com/bigdra50/dotfiles
WORKDIR /home/bigdra50/dev/github.com/bigdra50/dotfiles

CMD ["/bin/bash"]
