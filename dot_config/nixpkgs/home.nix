{ config, lib, pkgs, ... }:


{
  home.packages = with pkgs; [
    bat
    chezmoi
    curl
    delta
    fd
    fzf
    ghq
    git  
    git-lfs
    graphviz
    httpie
    nodePackages.npm
    nodejs
    openjdk
    python3
    ripgrep
    rustup
    tig
    tree
    wezterm
    wget
    yarn
    youtube-dl
    zoxide
  ];
  
  
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.language.base = "en_US.UTF-8";
  home.stateVersion = "22.11";
  
  
  programs.home-manager.enable = true;
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
    delta = {
      enable = true;
      options = {
        line-numbers = true;
        navigate = true;
        side-by-side = true;
        light = false;
      };
    };
    lfs = {
      enable = true;

    };
    extraConfig = {
      core = {
        whitespace = "trailing-space,space-before-tab";
        preloadindex = true;
        editor = "vim";
      };
      add.interactive = {
        useBuiltin = false;
      };
      color = {ui = "auto";};
      merge = {
        ff = "only";
        conflictstyle = "diff3";
      };
      diff = {
        colorMoved = "default";
      };
      pull = {
        ff = "only";
        rebase = false;
      };
      ghq = {
        root = "~/dev";
      };
  
      init.defaultBranch = "master";
    };
    ignores = [
      ".DS_Store"
    ];
  };
  
  programs.gh = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    withRuby = true;
    withNodeJs = true;
    withPython3 = true;
    extraConfig = lib.fileContents ~/.config/nvim/init.vim;
  };
  
  programs.fzf = {
    enable = true;
    defaultOptions = [
      "--bind=ctrl-k:kill-line"
      "--bind=ctrl-space:toggle"
      "--reverse" 
    ];
  };
  programs.bat.enable = true;
  programs.lsd.enable = true;

  programs.go = {
    enable = true;
  };
  
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  
}
