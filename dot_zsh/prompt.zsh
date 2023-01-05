# # プロンプト
# ## 色設定
# autoload -U colors; colors
# ## PCRE 互換の正規表現を使う
# setopt re_match_pcre
# ## プロンプトが表示されるたびプロンプト文字列を評価,置換する
# setopt prompt_subst
## プロンプト指定
# PROMPT="
# [%n] %{${fg[yellow]}%}%~%{${reset_color}%}
# %(?.%{$fg[green]%}.%{$fg[blue]%})%(?!(*'-') <!(*;-;%)? <)%{${reset_color}%} "
# ## プロンプト指定(コマンドの続き)
# PROMPT2='[%n]> '
# ## もしかして時のプロンプト指定
# SPROMPT="%{$fg[red]%}%{$suggest%}(*'~'%)? < もしかして %B%r%b %{$fg[red]%}かな? [そう!(y), 違う!(n),a,e]:${reset_color} "


#autoload -Uz vcs_info
#setopt prompt_subst
#zstyle ':vcs_info:git:*' check-for-changes true
#zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
#zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
#zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
#zstyle ':vcs_info:*' actionformats '[%b|%a]'
#precmd () { vcs_info }
#RPROMPT=$RPROMPT'${vcs_info_msg_0_}'
