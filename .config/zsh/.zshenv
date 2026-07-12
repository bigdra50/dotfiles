export LANG=ja_JP.UTF-8
export LANGUAGE='ja'

# PATH/FPATH の重複排除 (.zshenv は zsh のネスト起動ごとに毎回評価されるため、
# 無条件 prepend だけだとエントリが恒久的に増殖する)
# NOTE: scalar 代入 (export PATH=...) 経由でも効かせるには配列とスカラーの両方に -U が必要
typeset -gU path PATH fpath FPATH

# Homebrew (macOS) — PATH は env.zsh の正準順序で管理し、ここでは FPATH のみ
if [[ -d /opt/homebrew ]]; then
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

export CHEAT_CONFIG_PATH=$XDG_CONFIG_HOME/cheat/conf.yml

# mkdir XDG Base Directories
mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME $XDG_STATE_HOME $HOME/.local/{bin,src}

# fzf
if [ -e "$ZDOTDIR/plugins/fzf.zsh" ]; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'; \
  export FZF_DEFAULT_OPTS='--height 40% --reverse --border';
fi

# 正準 PATH 順序 + 常時 export (非対話シェルにも必要な環境) を適用。
# login shell では path_helper 対策として $ZDOTDIR/.zprofile からも再 source される。
[[ -f "$ZDOTDIR/env.zsh" ]] && . "$ZDOTDIR/env.zsh"

[[ -e "$ZDOTDIR/.zshenv_local" ]] && . "$ZDOTDIR/.zshenv_local"
