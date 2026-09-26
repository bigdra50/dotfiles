# zsh-abbr: fish-like abbreviations
# Session abbreviations (-S) for dotfiles-managed definitions
# User-added abbreviations are persisted in $XDG_CONFIG_HOME/zsh-abbr/user-abbreviations
#
# ABBR_DEFAULT_BINDINGS=0 (sheldon plugins.toml) でデフォルトバインディングを無効化し、
# abbr-expand + accept-line のカスタムウィジェットで Enter 時展開を実現。
# Space には abbr-expand-and-insert をバインドし、引数付きコマンドでも展開可能にする。

# zsh-abbr が利用可能なときだけキーバインドと略語を初期化する
_setup_abbr() {
if ! command -v abbr &>/dev/null; then
  return 0
fi

_abbr_accept() {
  zle abbr-expand
  BUFFER="${BUFFER%;}"
  zle accept-line
}
if [[ -o interactive && -o zle ]]; then
  zle -N _abbr_accept
  bindkey "^M" _abbr_accept
  bindkey " " abbr-expand-and-insert
  bindkey "^ " magic-space
fi

# 同名コマンドと重なる略語は、-f が無ければ登録されない
# -q だと -f の通知が起動のたびに出るので、-qq で抑える
abbr -S -qq -f add cp="cp -r"
abbr -S -qq -f add mkdir="mkdir -p"
abbr -S -qq -f add cut="choose"
abbr -S -qq -f add df="duf"
abbr -S -qq -f add du="dust"
abbr -S -q add restart="exec $SHELL -l"
abbr -S -qq -f add top="btm"
abbr -S -qq -f add diff="delta"

abbr -S -q add g="git"
abbr -S -q add v="nvim"
abbr -S -q add vz="nvim $ZDOTDIR/.zshrc"
abbr -S -q add vv="nvim ~/.config/nvim/init.lua"
abbr -S -q add vn="nvim ~/.config/nixpkgs/home.nix"
abbr -S -q add h="history"
abbr -S -q add so="source"
abbr -S -q add soz="source $HOME/.zshenv && source $ZDOTDIR/.zshrc"
abbr -S -q add c="claude"
abbr -S -q add yolo="claude --dangerously-skip-permissions"
abbr -S -q add vanilla="claude-vanilla"
abbr -S -q add vyolo="claude-vanilla --dangerously-skip-permissions"
abbr -S -q add cccommit="~/bin/cccommit.sh"
}

_setup_abbr
