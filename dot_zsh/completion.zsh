# -------------------------------
# 補完
# -------------------------------

setopt always_last_prompt # カーソル位置を保持したままファイル名一覧を順次その場で表示
setopt auto_list  # 補完候補が複数ある時に、一覧表示
setopt auto_menu  # 補完候補が複数あるときに自動的に一覧表示する
setopt auto_param_keys  # カッコの対応などを自動で補完
setopt auto_param_slash # ディレクトリ名の補完で末尾の/を自動的に追加する
setopt autoremoveslash
setopt complete_in_word  # 語の途中でもカーソル位置で補完
setopt correct  # コマンドミスを修正
setopt extended_glob  # 拡張グロブで補完(~とか^とか)
setopt glob_complete
setopt globdots # 明確なドットの指定なしで.から始まるファイルをマッチ
setopt hash_list_all
setopt list_ambiguous
setopt list_packed # 補完候補を詰めて表示
setopt list_rows_first
setopt list_types # 補完候補一覧でファイルの識別を識別マーク表示
setopt magic_equal_subst  # コマンドライン技奇数で --prefix=/usrなどの=以降も補完
setopt mark_dirs  # ファイル名の展開でディレクトリにマッチした場合末尾に/を追加
setopt menu_complete
setopt no_beep  # 補完候補がないときなどにビープ音を鳴らさない。
setopt no_flow_control
setopt rec_exact  
unsetopt menu_complete
unsetopt list_beep

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

zstyle ':autocomplete:*' insert-unambiguous yes
# no:  Tab inserts the top completion.
# yes: Tab first inserts a substring common to all listed completions, if any.

zstyle ':autocomplete:*' widget-style menu-select
# complete-word: (Shift-)Tab inserts the top (bottom) completion.
# menu-complete: Press again to cycle to next (previous) completion.
# menu-select:   Same as `menu-complete`, but updates selection in menu.
# ⚠️ NOTE: This setting can NOT be changed at runtime.

zstyle ':autocomplete:*' fzf-completion yes
# no:  Tab uses Zsh's completion system only.
# yes: Tab first tries Fzf's completion, then falls back to Zsh's.
# ⚠️ NOTE: This setting can NOT be changed at runtime and requires that you
# have installed Fzf's shell extensions.

# Add a space after these completions:
zstyle ':autocomplete:*' add-space \
    executables aliases functions builtins reserved-words commands

source $XDG_DATA_HOME/zinit/plugins/marlonrichert---zsh-autocomplete/zsh-autocomplete.plugin.zsh
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
#bindkey -M menuselect '\r' .accept-line
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
