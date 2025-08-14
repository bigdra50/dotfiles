# BATシンタックスハイライトでチートシート表示するため、#のコメント行を見やすくする
export BAT_THEME=zenburn

alias less='bat'
# pagingを無効
alias bat='bat --paging=auto'
# そのままのplain表示
alias -g L='|bat --style=plain'
# シンタックスハイライトの言語を指定
ch() { cheat $* | bat --style=plain -l sh }
# 表示範囲を指定（２行目以降）
pop() { cd $(dirs -lp | bat -r 2: | fzf --no-sort --prompt='cd >') }
