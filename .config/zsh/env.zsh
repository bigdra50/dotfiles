# env.zsh - 常時層: 正準 PATH 順序 + 非対話シェルにも必要な環境変数
#
# 以下の2箇所から source される:
#   - $ZDOTDIR/.zshenv   (すべての zsh 起動)
#   - $ZDOTDIR/.zprofile (login shell で /etc/zprofile の path_helper が PATH を
#                         再構成した後に、正準順序を再主張する)
# typeset -gU により再 source は冪等(重複は増えず順序だけ矯正される)。
# このファイルは毎 `zsh -c` で走るため、外部コマンドの fork を置かないこと。

typeset -gU path PATH fpath FPATH

# Go (mise 管理のツールチェーン; デフォルトの $HOME/go を明示して `go env` fork を回避)
export GOPATH=${GOPATH:-$HOME/go}

# cc-worklog: Claude Code の hook (非対話) が参照するため常時層に置く
export CC_WORKLOG_DIR="$HOME/workspace/task-mgr"

# 正準 PATH 順序。(N-/) は存在しないディレクトリを黙って除外する。
path=(
  # Haskell (ghcup; ~/.ghcup/env の PATH prepend を静的化)
  $HOME/.cabal/bin(N-/)
  $HOME/.ghcup/bin(N-/)
  # Unity CLI (~/.unity/env の PATH prepend を静的化。更新は `unity upgrade`)
  $HOME/.unity/bin(N-/)
  # mise shims: 対話/非対話を問わずランタイム解決の単一の真実
  ${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims(N-/)
  /opt/homebrew/bin(N-/)
  /opt/homebrew/sbin(N-/)
  $HOME/bin(N-/)
  $HOME/.local/bin(N-/)
  $HOME/.cargo/bin(N-/)
  $HOME/opt(N-/)
  # JetBrains Toolbox CLI ランチャ (rider1, studio 等)
  "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"(N-/)
  $path
  # --- 以降は後置 (システムパスより後ろでよいもの) ---
  $GOPATH/bin(N-/)
  # /etc/paths.d/dotnet-cli-tools はリテラル "~" を含み path_helper が展開しない。
  # 解決済みパスを後置して dotnet global tools を引けるようにする。
  $HOME/.dotnet/tools(N-/)
)
