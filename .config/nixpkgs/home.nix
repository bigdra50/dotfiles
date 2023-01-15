{ config, lib, pkgs, ... }:


{
  home.packages = with pkgs; [
    bat
    curl
    delta
    du-dust
    fd
    fzf
    gawk
    ghq
    git
    git-lfs
    graphviz
    gron
    httpie
    jq
    luajit
    neofetch
    nodePackages.npm
    nodejs
    openjdk
    procs
    python3
    ripgrep
    rustup
    sqlite
    tig
    tree
    tree-sitter
    wezterm
    wget
    yarn
    zoxide
    zsh
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
      color = { ui = "auto"; };
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
    extraConfig = ''
      set runtimepath+=${../nvim}
      source ~/.vimrc

      if &compatible
        set nocompatible
      endif

      source ~/.config/nvim/load-plugins.vim
      set laststatus=3
    '';
    plugins = [
      {
        plugin = pkgs.vimPlugins.auto-pairs;
      }
      {
        plugin = pkgs.vimPlugins.vimproc;
      }
      {
        plugin = pkgs.vimPlugins.nvim-web-devicons;
      }
      {
        plugin = pkgs.vimPlugins.vim-nix;
      }
      {
        plugin = pkgs.vimPlugins.nvim-notify;
      }
      {
        plugin = pkgs.vimPlugins.zoxide-vim;
      }
      {
        plugin = pkgs.vimPlugins.plenary-nvim;
      }
      {
        plugin = pkgs.vimPlugins.gruvbox-material;
        config = "source ~/.config/nvim/plugins/gruvbox.vim";
      }
      {
        plugin = pkgs.vimPlugins.toggleterm-nvim;
        config = "source ~/.config/nvim/plugins/toggleterm.vim";
      }
      {
        plugin = pkgs.vimPlugins.coc-nvim;
        config = "source ~/.config/nvim/plugins/coc.vim";
      }
      {
        plugin = pkgs.vimPlugins.sqlite-lua;
        config = "let g:sqlite_clib_path = '${pkgs.sqlite.out}/lib/libsqlite3.dylib'";
        # OSX: libsqlite3.dylib, other: libsqlite3.so
      }
      {
        plugin = pkgs.vimPlugins.telescope-nvim;
        config = "source ~/.config/nvim/plugins/telescope.vim";
      }
      {
        plugin = pkgs.vimPlugins.telescope-frecency-nvim;
        config = "source ~/.config/nvim/plugins/telescope-frecency.vim";
      }
      {
        plugin = pkgs.vimPlugins.telescope-coc-nvim;
        config = "source ~/.config/nvim/plugins/telescope-coc.vim";
      }
      {
        plugin = pkgs.vimPlugins.fern-vim;
        config = "source ~/.config/nvim/plugins/fern.vim";
      }
      {
        plugin = pkgs.vimPlugins.lualine-nvim;
        config = "source ~/.config/nvim/plugins/lualine.lua";
      }

      {
        plugin = pkgs.vimPlugins.hop-nvim;
        config = "source ~/.config/nvim/plugins/hop.vim";
      }
      {
        plugin = pkgs.vimPlugins.vim-quickrun;
        config = "source ~/.config/nvim/plugins/quickrun.vim";
      }

      {
        plugin = pkgs.vimPlugins.vim-gitgutter;
        config = "source ~/.config/nvim/plugins/gitgutter.vim";
      }
      {
        plugin = pkgs.vimPlugins.vim-fugitive;
        config = "source ~/.config/nvim/plugins/fugitive.vim";
      }
      {
        plugin = pkgs.vimPlugins.todo-comments-nvim;
        config = "source ~/.config/nvim/plugins/todo-comments.lua";
      }

      {
        plugin = pkgs.vimPlugins.gitsigns-nvim;
        config = "source ~/.config/nvim/plugins/gitsigns.lua";
      }
      {
        plugin = pkgs.vimPlugins.nvim-hlslens;
        config = "source ~/.config/nvim/plugins/hlslens.lua";
      }
      {
        plugin = pkgs.vimPlugins.nvim-scrollbar;
        config = "source ~/.config/nvim/plugins/scrollbar.lua";
      }

    ];
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
