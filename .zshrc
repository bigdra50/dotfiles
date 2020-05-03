ZSH_THEME="gnzh"
export LANG=ja_JP.UTF-8
if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

export PATH="{$PATH}:/c/Program Files/Git LFS"
export PATH=$PATH:/opt/gradle/gradle-6.3/bin  # gradleのパス

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
# history設定
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history

## history検索
### Ctrl-P/Ctlr-Nで,入力中の文字から始まるコマンドの履歴が表示
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# 補完
autoload -U compinit; compinit -C

## 補完候補ごとにグループ化
zstyle ':completion:*' format '%B%F{blue}%d%f%b'
zstyle ':completion:*' group-name ''
## select=2: 補完候補を一覧から選択する。補完候補が2つ以上なければすぐに補完する。
zstyle ':completion:*:default' menu select=2
## 補完候補に色を付ける。
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
## 補完候補がなければより曖昧に候補を探す
### m:{a-z}={A-Z}: 小文字を大文字に変えたものでも補完する。
### r:|[._-]=*: 「.」「_」「-」の前にワイルドカード「*」があるものとして補完する。
#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} r:|[._-]=*'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' keep-prefix
zstyle ':completion:*' recent-dirs-insert both

setopt no_beep  # 補完候補がないときなどにビープ音を鳴らさない。
setopt auto_cd  # ディレクトリ名だけで移動
setopt auto_pushd  # cd したら pushd
setopt auto_list  # 補完候補が複数ある時に、一覧表示
setopt auto_menu  # 補完候補が複数あるときに自動的に一覧表示する
setopt list_packed
setopt list_types
setopt no_flow_control
setopt print_eight_bit
setopt pushd_ignore_dups
setopt rec_exact
setopt autoremoveslash
unsetopt list_beep
setopt complete_in_word  # カーソル位置で補完する。
setopt correct  # コマンドミスを修正

# cd後にls
chpwd() { ls -a --color=auto }
# mkdir後にcd
# function mkcd() {
#   if [[ -d $1 ]]; then
#     echo "$1 already exists!"
#     cd $1
#   else
#     mkdir -p $1 && cd $1
#   fi
# }

# kawaii
## 色設定
autoload -U colors; colors
## PCRE 互換の正規表現を使う
setopt re_match_pcre
## プロンプトが表示されるたびプロンプト文字列を評価,置換する
setopt prompt_subst
## プロンプト指定
PROMPT="
[%n] %{${fg[yellow]}%}%~%{${reset_color}%}
%(?.%{$fg[green]%}.%{$fg[blue]%})%(?!(*'-') <!(*;-;%)? <)%{${reset_color}%} "
## プロンプト指定(コマンドの続き)
PROMPT2='[%n]> '
## もしかして時のプロンプト指定
SPROMPT="%{$fg[red]%}%{$suggest%}(*'~'%)? < もしかして %B%r%b %{$fg[red]%}かな? [そう!(y), 違う!(n),a,e]:${reset_color} "
#

autoload -Uz vcs_info
#setopt prompt_subst
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{red}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u[%b]%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'
precmd () { vcs_info }
RPROMPT=$RPROMPT'${vcs_info_msg_0_}'


#エイリアス
alias v='vim'
alias vz='vim ~/.zshrc'
alias vp='vim ~/.zpreztorc'
alias vv='vim ~/.vimrc'
alias h='history'
alias sshz='ssh s1260133@sshgate.u-aizu.ac.jp'
alias sshzy='ssh -Y s1260133@sshgate.u-aizu.ac.jp'
alias sftpz='sftp s1260133@sshgate.u-aizu.ac.jp'
alias so='source'
alias soz='source ~/.zshrc'
alias sov='source ~/.vimrc'
alias ls='ls -GF --color'
alias lsa='ls -aGF --color'
alias gls='gls --color'
alias lsl='ls -lh'
#alias mkdir='(){mkdir $1;cd $1}'
alias exp='explorer.exe'
alias open='cmd.exe /c start'
alias clip='clip.exe'
alias adb='adb.exe'

#cd /mnt/d/
cd /mnt/d/Workspace

export DISPLAY=localhost:0.0
