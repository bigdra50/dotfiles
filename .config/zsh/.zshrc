# TERM フォールバック: cmd.exe/PowerShell から wsl を直起動する等の経路では
# ターミナルが TERM を引き渡さず空になる。TERM が空 / dumb / terminfo エントリ無しのままだと
# $terminfo[...] 参照が全滅し、zsh-autocomplete のキーバインド生成が壊れて
# 入力が多重化する(1文字→複数文字) / 起動時に余分な改行が入る。安全な既定へ倒す。
# ターミナルが正しい TERM を渡す macOS 等では条件を満たさず何もしない。
if [[ -z "$TERM" || "$TERM" == dumb ]]; then
  export TERM=xterm-256color
elif command -v infocmp >/dev/null 2>&1 && ! infocmp "$TERM" >/dev/null 2>&1; then
  export TERM=xterm-256color
fi

# Show system info on startup (optional)
#command -v neofetch &>/dev/null && neofetch
[[ -f "$ZDOTDIR/environment.zsh" ]] && . "$ZDOTDIR/environment.zsh"
[[ -f "$ZDOTDIR/interface.zsh" ]] && . "$ZDOTDIR/interface.zsh"
[[ -f "$ZDOTDIR/extensions.zsh" ]] && . "$ZDOTDIR/extensions.zsh"

[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env

# ローカルオーバーライドは最後に読む (alias/function/plugin を上書きできるように)
[[ -f "$ZDOTDIR/.zshrc_local" ]] && . "$ZDOTDIR/.zshrc_local"