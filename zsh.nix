# WIP
{pkgs, ...}:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    # dotDir = ".config/zsh";

    enableCompletion = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
  };
}
