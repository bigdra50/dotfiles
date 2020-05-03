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
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=5'

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

setopt auto_param_slash # ディレクトリ名の補完で末尾の/を自動的に追加する
setopt auto_param_keys  # カッコの対応などを自動で補完
setopt auto_cd  # ディレクトリ名だけで移動
setopt auto_pushd  # cd したら pushd
setopt auto_list  # 補完候補が複数ある時に、一覧表示
setopt auto_menu  # 補完候補が複数あるときに自動的に一覧表示する
setopt autoremoveslash
setopt always_last_prompt # カーソル位置を保持したままファイル名一覧を順次その場で表示
setopt complete_in_word  # 語の途中でもカーソル位置で補完
setopt correct  # コマンドミスを修正
setopt extended_glob  # 拡張グロブで補完(~とか^とか)
setopt globdots # 明確なドットの指定なしで.から始まるファイルをマッチ
setopt interactive_comments # コマンドラインでも#以降をコメントとみなす
setopt list_packed
setopt list_types # 補完候補一覧でファイルの識別を識別マーク表示
setopt magic_equal_subst  # コマンドライン技奇数で --prefix=/usrなどの=以降も補完
setopt mark_dirs  # ファイル名の展開でディレクトリにマッチした場合末尾に/を追加
setopt no_beep  # 補完候補がないときなどにビープ音を鳴らさない。
setopt no_flow_control
setopt print_eight_bit  # 日本語ファイル名など8bitを通す
setopt pushd_ignore_dups
setopt rec_exact
unsetopt list_beep

bindkey "^I" menu-complete  # 展開する前に補完候補を出させる(Ctrl-iで補完)

# 範囲指定できるようにする
# 例: mkdir {1-3}でフォルダ1, 2, 3を作れる
setopt brace_ccl

# 変数の添字を補完する
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# aptやdpkgコマンドをキャッシュ
zstyle ':completion:*' use-cache true

# カレントディレクトリに候補がない場合のみcdpath上のディレクトリを候補に出す
zstyle ':completion:*:cd:*' tag-order local-directories path-directories


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
