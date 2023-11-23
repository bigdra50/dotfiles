# extensions.zsh
[[ -f ~/.zsh/zinit.zsh ]] && . ~/.zsh/zinit.zsh
[[ -f ~/.zsh/func.zsh ]] && . ~/.zsh/func.zsh
[[ -f ~/.zsh/history.zsh ]] && . ~/.zsh/history.zsh
[[ -f ~/.zsh/completion.zsh ]] && . ~/.zsh/completion.zsh
[[ -f ~/.zsh/alias.zsh ]] && . ~/.zsh/alias.zsh

# load plugins config
while read -d $'\0' f; do
  [[ -f ${f} ]] && . ${f}
done < <(find ~/.zsh/plugins -mindepth 1 -maxdepth 1 -print0)

