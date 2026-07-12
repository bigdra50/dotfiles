# func-core.zsh - 常時層の関数 (対話/非対話を問わず必要なもの)
#
# $ZDOTDIR/.zshenv から source される。Claude Code のツールシェルやスクリプトの
# `zsh -c` でも効かせたい関数だけを置く。対話専用 (fzf 等の UI を伴うもの) は
# func.zsh (extensions.zsh 経由 = .zshrc チェーン) に置くこと。

#
# for gh (GitHub CLI)
#
# cwd の org ディレクトリごとに GH_CONFIG_DIR を出し分けてアカウントを固定する。
# トークンは keyring 共有なので各 config dir は hosts.yml だけでよい。
# 具体的な org→config dir の対応は連想配列 GH_ORG_CONFIG で与える。
# 職場など公開できない対応は非追跡の .zshenv_local 側で定義すること:
#   typeset -gA GH_ORG_CONFIG=( github.com/<org> gh-<config-dir> ... )
# GH_ORG_CONFIG 未定義/不一致ならデフォルト ($XDG_CONFIG_HOME/gh) にフォールバックする。
gh(){
  local base="${XDG_CONFIG_HOME:-$HOME/.config}" k cfg=""
  if (( ${+GH_ORG_CONFIG} )); then
    for k in ${(k)GH_ORG_CONFIG}; do
      case $PWD/ in
        */$k/*) cfg="$base/${GH_ORG_CONFIG[$k]}"; break ;;
      esac
    done
  fi
  if [[ -n $cfg ]]; then
    GH_CONFIG_DIR="$cfg" command gh "$@"
  else
    command gh "$@"
  fi
}
