export LANG=ja_JP.UTF-8
export LANGUAGE='ja'

# Homebrew (macOS)
if [[ -d /opt/homebrew ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  export FPATH="/opt/homebrew/share/zsh/site-functions:$FPATH"
fi

# WSL/Linux 固有設定
if [[ "$OSTYPE" == linux* ]]; then
  export GTK_IM_MODULE=fcitx
  export QT_IM_MODULE=fcitx
  export XMODIFIERS=@im=fcitx
  export DefaultIMModule=fcitx
  export LIBGL_ALWAYS_INDIRECT=1
  [[ -r /etc/resolv.conf ]] && export DISPLAY="$(awk '/nameserver/{print $2; exit}' /etc/resolv.conf):0.0"
fi
export EDITOR=nvim

# Roslyn LSP: Unity の .csproj (TargetFrameworkVersion v4.7.1) 用に Mono 参照アセンブリを指定
export FrameworkPathOverride="/Library/Frameworks/Mono.framework/Versions/Current/lib/mono/4.7.2-api"

# export XDG Base Directories
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state

export PATH=$HOME/opt:$PATH
export CHEAT_CONFIG_PATH=$XDG_CONFIG_HOME/cheat/conf.yml
export PATH=$HOME/.local/bin:$PATH

# Cargo tools (auto-installed via dotfiles)
export PATH=$HOME/.cargo/bin:$PATH


# mkdir XDG Base Directories
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME $XDG_STATE_HOME $HOME/.local/{bin,src}

# fzf
if [ -e "$ZDOTDIR/plugins/fzf.zsh" ]; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'; \
  export FZF_DEFAULT_OPTS='--height 40% --reverse --border';
fi

[[ -e "$ZDOTDIR/.zshenv_local" ]] && . "$ZDOTDIR/.zshenv_local"
