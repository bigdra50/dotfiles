{
  description = "bigdra50/dotfiles — Nix migration experiment (Home Manager standalone)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      mkHome =
        { system, hostModule }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./home.nix
            hostModule
          ];
        };
    in
    {
      # `home-manager switch --flake ./nix#<name>` で適用する。
      homeConfigurations = {
        # WSL Ubuntu / Linux（Docker 検証もこのプロファイル）
        wsl = mkHome {
          system = "x86_64-linux";
          hostModule = ./hosts/wsl.nix;
        };

        # macOS（Apple Silicon）。Linux ではビルド検証できないためスケルトン。
        mac = mkHome {
          system = "aarch64-darwin";
          hostModule = ./hosts/mac.nix;
        };
      };
    };
}
