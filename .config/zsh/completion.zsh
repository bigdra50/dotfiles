# -------------------------------
# 補完
# -------------------------------

setopt always_last_prompt
setopt auto_list
setopt auto_menu
setopt auto_param_keys
setopt auto_param_slash
setopt autoremoveslash
setopt complete_in_word
setopt correct
setopt extended_glob
setopt glob_complete
setopt globdots
setopt hash_list_all
setopt list_ambiguous
setopt list_packed
setopt list_rows_first
setopt list_types
setopt magic_equal_subst
setopt mark_dirs
setopt no_beep
setopt no_flow_control
setopt rec_exact
unsetopt menu_complete
unsetopt list_beep

# --- fzf-tab 設定 ---
# fzf-tab に制御を渡す（標準メニューを無効化）
zstyle ':completion:*' menu no

# 補完候補にグループヘッダを表示
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' group-name ''

# LS_COLORS で色付け
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# 大文字小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# キャッシュ有効化
zstyle ':completion:*' use-cache true

# 変数の添字を補完する
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# --- fzf-tab プレビュー ---
# cd: ディレクトリ内容をプレビュー
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd -1 --color=always $realpath'

# 汎用: ファイルはbat、ディレクトリはlsd
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '[[ -d $realpath ]] && lsd --tree --depth=2 --color=always $realpath || bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null'

# git: diff プレビュー
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --oneline --color=always $word'

# / でディレクトリを掘り下げ
zstyle ':fzf-tab:*' continuous-trigger '/'

# fzf のデフォルトオプションを継承
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# --- carapace: 1600+ CLIツールの補完を一括提供 ---
if command -v carapace &> /dev/null; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
  if command -v zsh-defer &> /dev/null; then
    zsh-defer eval "$(carapace _carapace zsh)"
  else
    eval "$(carapace _carapace zsh)"
  fi
fi

# --- autosuggestions ---
# completion 戦略は履歴に無い入力で補完エンジン由来のゴースト候補を出し、
# WSL/ConPTY 上では表示ノイズ(打っていない文字が見える)の一因になる。履歴ベースのみに絞る。
ZSH_AUTOSUGGEST_STRATEGY=(history)

# キーバインド
bindkey '\e[A' up-line-or-search
bindkey '\eOA' up-line-or-search
bindkey '\e[B' down-line-or-select
bindkey '\eOB' down-line-or-select
bindkey "^N" menu-complete
bindkey "^E" autosuggest-accept
