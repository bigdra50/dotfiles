# extensions.zsh
# Plugin manager: sheldon
if command -v sheldon &>/dev/null; then
  # zsh-autocomplete は plugins.toml で profiles=["macos"] 指定。macOS のときだけ
  # SHELDON_PROFILE=macos を立てて読み込む。WSL/Linux(ConPTY) では読み込まない。
  [[ "$OSTYPE" == darwin* ]] && export SHELDON_PROFILE=macos
  eval "$(sheldon source 2>/dev/null)"
fi
[[ -f "$ZDOTDIR/func.zsh" ]] && . "$ZDOTDIR/func.zsh"
[[ -f "$ZDOTDIR/history.zsh" ]] && . "$ZDOTDIR/history.zsh"
[[ -f "$ZDOTDIR/completion.zsh" ]] && . "$ZDOTDIR/completion.zsh"
[[ -f "$ZDOTDIR/alias.zsh" ]] && . "$ZDOTDIR/alias.zsh"

# load plugins config
for f in "$ZDOTDIR"/plugins/*.zsh(N); do . $f; done
