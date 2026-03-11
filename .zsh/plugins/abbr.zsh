# zsh-abbr: fish-like abbreviations
# Session abbreviations (-S) for dotfiles-managed definitions
# User-added abbreviations are persisted in $XDG_CONFIG_HOME/zsh-abbr/user-abbreviations

abbr -S -q add cp='cp -r'
abbr -S -q add mkdir='mkdir -p'
abbr -S -q add cut='choose'
abbr -S -q add df='duf'
abbr -S -q add du='dust'
abbr -S -q add restart='exec $SHELL -l'
abbr -S -q add top='btm'
abbr -S -q add diff='delta'

abbr -S -q add g='git'
abbr -S -q add v='nvim'
abbr -S -q add vz='nvim ~/.zshrc'
abbr -S -q add vv='nvim ~/.config/nvim/init.lua'
abbr -S -q add vn='nvim ~/.config/nixpkgs/home.nix'
abbr -S -q add h='history'
abbr -S -q add so='source'
abbr -S -q add soz='source $HOME/.zshenv && source $HOME/.zshrc'
abbr -S -q add yolo='claude --dangerously-skip-permissions'
abbr -S -q add cccommit='~/bin/cccommit.sh'
