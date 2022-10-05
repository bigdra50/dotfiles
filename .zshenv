export LANG=ja_JP.UTF-8
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx
export LIBGL_ALWAYS_INDIRECT=1
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export PATH=$HOME/opt:$PATH

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh \
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'; \
  export FZF_DEFAULT_OPTS='--height 40% --reverse --border';

. /opt/homebrew/opt/asdf/asdf.sh

[[ -e ~/.zshenv_local ]] && source ~/.zshenv_local
