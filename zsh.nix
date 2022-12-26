# WIP
{pkgs, ...}:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    shellAliases = {
      cp = "cp -r";
      mkdir = "mkdir -p";
      rm = "trash -rf";
      cut = "choose";
      df = "duf";
      du = "dust";
      restart = "exec $SHELL -l";
      top = "btm";
      diff = "delta";
      sl = "lsd";
      ls = "lsd";
      l = "lsd -l";
      la = "lsd -la";
      ip = "ip --color=auto";
      g = "git";
      v = "nvim";
      h = "history";
    };
  };
}
