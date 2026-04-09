# extensions.zsh
# Plugin manager: sheldon
eval "$(sheldon source 2>/dev/null)"
[[ -f "$ZDOTDIR/func.zsh" ]] && . "$ZDOTDIR/func.zsh"
[[ -f "$ZDOTDIR/history.zsh" ]] && . "$ZDOTDIR/history.zsh"
[[ -f "$ZDOTDIR/completion.zsh" ]] && . "$ZDOTDIR/completion.zsh"
[[ -f "$ZDOTDIR/alias.zsh" ]] && . "$ZDOTDIR/alias.zsh"

# load plugins config
for f in "$ZDOTDIR"/plugins/*.zsh(N); do . $f; done

