# helper for cheat sheets
ch() { cheat $* | bat --style=plain -l sh }

# blank line breaks comment run

pop(){ cd $(dirs -lp | fzf) }

function history-all { history -E 1 }

# zle widget
ghq-fzf() {
  local src=$(ghq list | fzf)
}
