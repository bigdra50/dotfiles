# ─── claude-vanilla ────────────────────────────────────────────
#
# 手持ちのプロンプト資産（CLAUDE.md、rules、auto memory、hooks、プラグイン、
# エージェント、MCP、Claude in Chrome、output style）を読ませず、素の Claude Code を起動する。
# 以前のモデル向けに整えた指示が、新しいモデルの足を引っ張っていないかを切り分けるのに使う。
#
# どのモードでも、認証、model、effort、permissions、language は通常どおり適用される。
# statusLine は --skills と --project でだけ表示される。
# safe mode は管理者設定（managed settings）の statusLine しか実行しないため。
# 既存のセッションを --resume すると、そのセッションに記録済みの文脈は残る。
#
# 検証:
#   python3 -m unittest scripts/tests/test_claude_vanilla.py            # 渡す引数の組み立て
#   CLAUDE_VANILLA_E2E=1 python3 -m unittest scripts/tests/test_claude_vanilla_e2e.py  # 実際に読み込まれる内容

# claude-vanilla [--skills] [--project] [claude の引数...]
#   指定なし   素の状態（公式の --safe-mode）
#   --skills   素の状態に ~/.claude/skills のスキルだけ足す（名前に my: が付く）
#   --project  個人の資産を外し、リポジトリの共有設定（CLAUDE.md、AGENTS.md、.claude/、.mcp.json）だけ読む
#   それ以外の引数は claude へ渡す（例: claude-vanilla --skills --dangerously-skip-permissions -c）
claude-vanilla() {
    emulate -L zsh
    local skills=0 project=0
    local -a pass
    while (($#)); do
        case $1 in
            --skills) skills=1 ;;
            --project) project=1 ;;
            --)
                pass+=("$@")
                break
                ;;
            *) pass+=("$1") ;;
        esac
        shift
    done

    # 素の状態は公式の safe mode に任せる。
    # 無効化する対象は Anthropic 側が保守するので、資産の種類が増えても漏れない。
    if ((!skills && !project)); then
        claude --safe-mode "${pass[@]}"
        return
    fi

    # safe mode は --plugin-dir などで明示しても、スキルもリポジトリ設定も読まない。
    # そこで読み込み元（setting sources）を絞り、残したいものだけを明示的に足す。
    local config=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
    local cache=${XDG_CACHE_HOME:-$HOME/.cache}/claude-vanilla
    local sources= prefs
    ((project)) && sources=project
    # Chrome 連携は ~/.claude.json の既定値で有効になり、setting sources では外れない。
    # safe mode と同じく切っておき、後ろに --chrome を渡されたらそちらを優先する（後勝ち）
    local -a opts=(--setting-sources "$sources" --no-chrome)
    # auto memory と claude.ai コネクタも setting sources で絞れないので個別に切る
    local -a envs=(CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 ENABLE_CLAUDEAI_MCP_SERVERS=false)
    if ((!project)); then
        # 読み込み元が空なら CLAUDE.md も MCP 設定も読まれないが、仕様変更に備えて二重に止める
        opts+=(--strict-mcp-config)
        envs+=(CLAUDE_CODE_DISABLE_CLAUDE_MDS=1)
    fi
    if prefs=$(_claude_vanilla_prefs "$config" "$cache"); then
        opts+=(--settings "$prefs")
    fi
    if ((skills)); then
        opts+=(--plugin-dir "$(_claude_vanilla_skills_plugin "$config" "$cache")")
    fi
    env "${envs[@]}" claude "${opts[@]}" "${pass[@]}"
}

# 個人の settings.json から、プロンプトや拡張を持ち込むキーを除いた写しを作り、そのパスを返す。
# 除くキーは safe mode が無効化する分類（hooks、プラグイン、MCP、output style、エージェント）に合わせてある。
# --settings は project の設定より優先されるので、--project で同じキーがあると個人の値が勝つ（通常起動とは逆）。
_claude_vanilla_prefs() {
    emulate -L zsh
    local src=$1/settings.json dst=$2/settings.json
    [[ -r $src ]] || return 1
    mkdir -p "$2" || return 1
    if ! jq 'del(.hooks, .enabledPlugins, .extraKnownMarketplaces, .mcpServers, .outputStyle, .agent)' \
        "$src" >"$dst.$$"; then
        rm -f "$dst.$$"
        print -u2 "claude-vanilla: $src を読めないため、個人設定を引き継がずに起動する"
        return 1
    fi
    mv -f "$dst.$$" "$dst"
    print -r -- "$dst"
}

# ~/.claude/skills を --plugin-dir で渡せるプラグインに包み、そのパスを返す。
# 読み込み元からユーザー設定を外すとユーザースキルも読まれなくなるため、プラグインとして足し直す。
_claude_vanilla_skills_plugin() {
    emulate -L zsh
    local config=$1 root=$2/skills-plugin
    local dir=$root/skills src name link
    local -a off
    local -A want
    mkdir -p "$root/.claude-plugin" "$dir"
    print -r -- '{"name": "my", "description": "~/.claude/skills wrapped by claude-vanilla"}' \
        >"$root/.claude-plugin/plugin.json"
    # 通常起動で skillOverrides により off にしているスキルは、ここでも外す
    if [[ -r $config/settings.json ]]; then
        off=(${(f)"$(jq -r '.skillOverrides // {} | to_entries[] | select(.value == "off") | .key' \
            "$config/settings.json")"})
    fi
    for src in "$config"/skills/*(N-/); do
        name=${src:t}
        [[ -f $src/SKILL.md ]] || continue
        ((${off[(Ie)$name]})) && continue
        want[$name]=$src
    done
    # 起動中の別セッションも同じディレクトリを読むので、作り直さずに差分だけ同期する
    for link in "$dir"/*(N@); do
        [[ ${want[${link:t}]-} == "$(readlink "$link")" ]] || rm -f "$link"
    done
    for name src in "${(@kv)want}"; do
        [[ -L $dir/$name ]] || ln -s "$src" "$dir/$name"
    done
    print -r -- "$root"
}
