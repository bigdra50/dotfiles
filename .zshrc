# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -------------------------------
# zinit
# -------------------------------
### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# -------------------------------
# plugin list
# -------------------------------

# zinit ice wait lucid
# zinit light zsh-users/zsh-completions
zinit ice wait lucid
zinit light marlonrichert/zsh-autocomplete
zinit light zsh-users/zsh-autosuggestions
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting
zinit ice wait lucid
zinit light chrissicool/zsh-256color
zinit ice depth=1
zinit light romkatv/powerlevel10k

# wslのrcファイルでこの設定をするとGUI描画時に古いOpenGLが使われてしまうことがあるため､ unsetしている
# wsl以外の環境ではいらない?
unset LIBGL_ALWAYS_INDIRECT


# vimキーバインドへ
bindkey -v
bindkey "jj" vi-cmd-mode

# -------------------------------
# history設定
# -------------------------------

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

# -------------------------------
# syntax highlighting 
# -------------------------------


case ${OSTYPE} in
  darwin*)
    export LSCOLORS=cxfxcxdxbxegedabagacad
    ;;
  linux*)
    eval $(dircolors -b ~/.colorrc)
    ;;
esac

# -------------------------------
# 補完
# -------------------------------
zstyle ':autocomplete:*' default-context ''
# '': Start each new command line with normal autocompletion.
# history-incremental-search-backward: Start in live history search mode.

zstyle ':autocomplete:*' min-delay 0.05  # float
# Wait this many seconds for typing to stop, before showing completions.

zstyle ':autocomplete:*' min-input 0  # int
# Wait until this many characters have been typed, before showing completions.

zstyle ':autocomplete:*' ignored-input '' # extended glob pattern
# '':     Always show completions.
# '..##': Don't show completions when the input consists of two or more dots.

zstyle ':autocomplete:*' list-lines 16  # int
# If there are fewer than this many lines below the prompt, move the prompt up
# to make room for showing this many lines of completions (approximately).

zstyle ':autocomplete:history-search:*' list-lines 16  # int
# Show this many history lines when pressing ↑.

zstyle ':autocomplete:history-incremental-search-*:*' list-lines 16  # int
# Show this many history lines when pressing ⌃R or ⌃S.

zstyle ':autocomplete:*' recent-dirs cdr
# cdr:  Use Zsh's `cdr` function to show recent directories as completions.
# no:   Don't show recent directories.
# zsh-z|zoxide|z.lua|z.sh|autojump|fasd: Use this instead (if installed).
# ⚠️ NOTE: This setting can NOT be changed at runtime.

zstyle ':autocomplete:*' insert-unambiguous no
# no:  Tab inserts the top completion.
# yes: Tab first inserts a substring common to all listed completions, if any.

zstyle ':autocomplete:*' widget-style complete-word
# complete-word: (Shift-)Tab inserts the top (bottom) completion.
# menu-complete: Press again to cycle to next (previous) completion.
# menu-select:   Same as `menu-complete`, but updates selection in menu.
# ⚠️ NOTE: This setting can NOT be changed at runtime.

zstyle ':autocomplete:*' fzf-completion no
# no:  Tab uses Zsh's completion system only.
# yes: Tab first tries Fzf's completion, then falls back to Zsh's.
# ⚠️ NOTE: This setting can NOT be changed at runtime and requires that you
# have installed Fzf's shell extensions.

# Add a space after these completions:
zstyle ':autocomplete:*' add-space \
    executables aliases functions builtins reserved-words commands

#source /path/to/zsh-autocomplete.plugin.zsh
##
# ⚠️ NOTE: All configuration below should come AFTER sourcing zsh-autocomplete!
#

# Up arrow:
bindkey '\e[A' up-line-or-search
bindkey '\eOA' up-line-or-search
# up-line-or-search:  Open history menu.
# up-line-or-history: Cycle to previous history line.

# Down arrow:
bindkey '\e[B' down-line-or-select
bindkey '\eOB' down-line-or-select
# down-line-or-select:  Open completion menu.
# down-line-or-history: Cycle to next history line.

# Control-Space:
bindkey '\0' list-expand
# list-expand:      Reveal hidden completions.
# set-mark-command: Activate text selection.

# Uncomment the following lines to disable live history search:
# zle -A {.,}history-incremental-search-forward
# zle -A {.,}history-incremental-search-backward

# Return key in completion menu & history menu:
bindkey -M menuselect '\r' .accept-line
# .accept-line: Accept command line.
# accept-line:  Accept selection and exit menu.
#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=5'

bindkey "^I" menu-complete  # 展開する前に補完候補を出させる(Ctrl-iで補完)
bindkey "^E" autosuggest-accept


# 変数の添字を補完する
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# aptやdpkgコマンドをキャッシュ
zstyle ':completion:*' use-cache true

# カレントディレクトリに候補がない場合のみcdpath上のディレクトリを候補に出す
## 補完候補ごとにグループ化
# zstyle ':completion:*' format '%B%F{blue}%d%f%b'
# zstyle ':completion:*' group-name ''
# ## select=2: 補完候補を一覧から選択する。補完候補が2つ以上なければすぐに補完する。
# zstyle ':completion:*:default' menu select=2
# ## 補完候補に色を付ける。
# zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# ## 補完候補がなければより曖昧に候補を探す
# ### m:{a-z}={A-Z}: 小文字を大文字に変えたものでも補完する。
# ### r:|[._-]=*: 「.」「_」「-」の前にワイルドカード「*」があるものとして補完する。
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} r:|[._-]=*'
# zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# zstyle ':completion:*' keep-prefix
# zstyle ':completion:*' recent-dirs-insert both

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

# 範囲指定できるようにする
# 例: mkdir {1-3}でフォルダ1, 2, 3を作れる
setopt brace_ccl

# load prompt settings
#source ~/.zsh/prompt.zsh
# load alias
source ~/.zsh/alias.zsh
# load functions
source ~/.zsh/func.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
