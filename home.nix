{ config, pkgs, ... }:
let
  editor = "vim";

in {
  #imports = [ ./vim.nix ];

  home.packages = with pkgs; [
    # dev tools
    git  
    ghq
    rustup
    
    # Python

    # CLI tools
    fzf
    ripgrep
    tree
    bat

    #cacheix
  ];

  programs.home-manager.enable = true;

  home.username = "bigdra";
  home.homeDirectory = "/Users/bigdra";
  home.stateVersion = "22.11";


  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    userName = "bigdra";
    userEmail = "bigdra50@gmail.com";
    aliases = {
      st = "status";
      tree = "log --graph --all --format='%x09%C(cyan bold)%an%Creset%x09%C(yellow)%h%Creset %C(magenta reverse)%d%Creset %s'";
    };
    extraConfig = {
      core = {
        whitespace = "trailing-space,space-before-tab";
        preloadindex = true;
      };
      color = {ui = "auto";};
      merge = {ff = "only";};
      pull = {
        ff = "only";
        rebase = false;
      };
      init.defaultBranch = "master";
    };
    ignores = [
      ".DS_Store"

    ];
  };

  programs.aria2.enable = true;
  programs.fzf.enable = true;
  programs.bat.enable = true;
  programs.lsd.enable = true;

  home.sessionVariables = {
    EDITOR = "${editor}";
  };

}
