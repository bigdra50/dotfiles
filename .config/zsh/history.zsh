# -------------------------------
# history
# -------------------------------

# コマンド履歴を保存するファイルを設定
mkdir -p "$XDG_STATE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"

# メモリ内のコマンド履歴に保存するエントリの数を設定
HISTSIZE=10000

# 履歴ファイルに保存するエントリの数を設定
SAVEHIST=100000

# 重複する履歴エントリを無視
setopt hist_ignore_all_dups

# 直後に続く重複する履歴行を無視
setopt hist_ignore_dups

# ターミナルセッション間でコマンド履歴を共有
setopt share_history

# 履歴をファイルに追記（上書きしない）
setopt append_history

# 履歴の展開を許可
setopt hist_expand

# 実行されるたびに各コマンドを履歴ファイルに追記
setopt inc_append_history

# 特定のコマンドの履歴保存を防止
setopt hist_no_store

# 履歴の各コマンドラインから余分な空白を削除
setopt hist_reduce_blanks

# 履歴ファイルにコマンドの実行時刻を記録
setopt extended_history

# コマンドが実行されてから一定時間が経過すると履歴が保存される
setopt inc_append_history_time

# atuin がキーバインド (Ctrl-R, Up/Down) を管理するため、Zsh側のバインドは不要
# 全コマンド履歴を表示するカスタム関数
function history-all { history -E 1 }

