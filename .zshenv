export LANG=ja_JP.UTF-8
export LANGUAGE='ja'
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx
export LIBGL_ALWAYS_INDIRECT=1
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0.0

# export XDG Base Directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

export PATH=$HOME/opt:$PATH
export CHEAT_CONFIG_PATH=$XDG_CONFIG_HOME/cheat/conf.yml


# mkdir XDG Base Directories
mkdir -p $XDG_CONFIG_HOME
mkdir -p $XDG_CACHE_HOME
mkdir -p $XDG_DATA_HOME
mkdir -p $XDG_STATE_HOME

mkdir -p $HOME/.local/bin
mkdir -p $HOME/.local/src

# fzf
if [ -e ~/.zsh/plugins/fzf.zsh ]; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'; \
  export FZF_DEFAULT_OPTS='--height 40% --reverse --border';
fi

[[ -e ~/.zshenv_local ]] && . ~/.zshenv_local

# if [ -e /home/bigdra/.nix-profile/etc/profile.d/nix.sh ]; then . /home/bigdra/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
