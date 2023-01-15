# ファイル→ディレクトの順でほぼ全て表示（.と..は除く）
alias ls='lsd -F --group-dirs=first'
# サイズが人に優しいリスト表示で、ディレクトリのサイズは中のファイルの合計を表示
alias ll='ls -hl --total-size'
alias la="ls -A"
alias lal='ll -A'

# chpwd(){
#   lsd -F --group-dirs=first
# }

# ツリー表示
alias tree='lsd -A --tree --group-dirs=first'
# ツリー形式でファイル情報も表示
alias lr='lsd -Ahl --total-size --tree --group-dirs=first'
