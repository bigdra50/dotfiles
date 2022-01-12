ZSH_THEME="gnzh"
unset LIBGL_ALWAYS_INDIRECT

if [ ! -e "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  echo "install zsh-syntax-highlighting"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh
  source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ ! -e "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  echo "install zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

case ${OSTYPE} in
  darwin*)
    ;;
  linux*)
    eval $(dircolors -b ~/.colorrc)
    ;;
esac

# vimキーバインドへ
bindkey -v

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

if [ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
else
  printf "\e[31m%s\n\e[m" "~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh is not found"
fi
# 補完
autoload -U compinit; compinit -C
if [ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
else
  printf "\e[31m%s\n\e[m" "~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh is not found"
fi
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
bindkey "^E" autosuggest-accept

# 範囲指定できるようにする
# 例: mkdir {1-3}でフォルダ1, 2, 3を作れる
setopt brace_ccl

# 変数の添字を補完する
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# aptやdpkgコマンドをキャッシュ
zstyle ':completion:*' use-cache true

# カレントディレクトリに候補がない場合のみcdpath上のディレクトリを候補に出す
zstyle ':completion:*:cd:*' tag-order local-directories path-directories

# load prompt settings
source ~/.zsh/prompt.zsh
# load alias
source ~/.zsh/alias.zsh
# load functions
source ~/.zsh/func.zsh
