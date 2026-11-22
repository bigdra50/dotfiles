#!/usr/bin/env bash
# apm (Microsoft Agent Package Manager) で skills と agents をユーザースコープへ入れる。
#
# 正本は dotfiles の .apm/apm.yml と .apm/apm.lock.yaml、ローカルの agent は .apm/agents。
# `mise run setup:claude` と、chezmoi の run_onchange スクリプトの両方がここを呼ぶ。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$DOTFILES_DIR/scripts/lib.sh"

# apm CLI のバージョン (release tarball を固定取得する)
APM_VERSION="0.28.0"

# apm (Microsoft Agent Package Manager) を sudo 無しで ~/.local に導入する。
# 公式インストーラ (curl https://aka.ms/apm-unix | sh) は /usr/local/bin へ sudo
# 導入するため、非対話・パスワード無しの環境で失敗する。ここでは release tarball を
# ~/.local/share/apm へ展開し ~/.local/bin/apm に symlink する。apm は PyInstaller
# onedir バンドルなので、単体バイナリではなく _internal/ ごと配置する必要がある。
# apm のバージョンは lockfile のスキーマを決める。0.23 系と 0.27 系では
# apm.lock.yaml の形式が違い、混在すると setup のたびに数千行の差分が出る。
# そのため「入っていれば何もしない」ではなく、pin へ収束させる。
# ただし収束させられるのは dotfiles が置いた ~/.local の実体だけで、
# パッケージマネージャ管理のものは奪わずに不一致を報告する。
apm_current_version() {
    apm --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

ensure_apm() {
    if command_exists apm; then
        local cur path
        cur="$(apm_current_version)"
        path="$(command -v apm)"
        if [[ "$cur" == "$APM_VERSION" ]]; then
            success "apm $cur ($path)"
            return 0
        fi
        if [[ "$path" != "$HOME/.local/bin/apm" ]]; then
            warning "apm $cur at $path is not managed by dotfiles (pin is $APM_VERSION)"
            warning "Version drift changes the apm.lock.yaml schema; align it manually or drop that copy"
            return 0
        fi
        info "apm $cur -> $APM_VERSION (re-installing dotfiles copy)"
    fi

    local arch os tarball url tmp extracted
    # 資産名は apm-<darwin|linux>-<arm64|x86_64>.tar.gz。uname の綴り
    # (Darwin / aarch64) とは違うので、そのまま流用すると 404 になる。
    case "$(uname -m)" in
        x86_64 | amd64) arch="x86_64" ;;
        aarch64 | arm64) arch="arm64" ;;
        *)
            warning "Unsupported arch for apm ($(uname -m)); skipping skills"
            return 1
            ;;
    esac
    case "$(uname -s)" in
        Darwin*) os="darwin" ;;
        Linux*) os="linux" ;;
        *)
            warning "Unsupported OS for apm; skipping skills"
            return 1
            ;;
    esac
    tarball="apm-${os}-${arch}.tar.gz"
    url="https://github.com/microsoft/apm/releases/download/v${APM_VERSION}/${tarball}"

    info "Installing apm ${APM_VERSION} to ~/.local (sudo-free)..."
    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/apm.tar.gz" "$url"; then
        warning "Failed to download apm; skipping skills"
        rm -rf "$tmp"
        return 1
    fi
    tar xzf "$tmp/apm.tar.gz" -C "$tmp"
    extracted="$(find "$tmp" -maxdepth 1 -type d -name 'apm-*' | head -1)"
    if [[ -z "$extracted" ]]; then
        warning "Unexpected apm archive layout; skipping skills"
        rm -rf "$tmp"
        return 1
    fi
    mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
    rm -rf "$HOME/.local/share/apm"
    mv "$extracted" "$HOME/.local/share/apm"
    ln -sf "$HOME/.local/share/apm/apm" "$HOME/.local/bin/apm"
    rm -rf "$tmp"
    export PATH="$HOME/.local/bin:$PATH"
    command_exists apm && success "apm installed ($(apm --version 2>/dev/null | head -1))"
}

# 旧 skillpm (`npx skills add`) が残した収束レイアウトを撤去する。
# skillpm は実体を ~/.agents/skills に置き ~/.claude/skills/<name> をそこへ symlink
# する。apm は実体を ~/.claude/skills に直接配置するため、両者が衝突しないよう
# skillpm 状態を検出したらバックアップして退避する (apm 管理下では no-op)。
cleanup_legacy_skillpm() {
    local skills_dir="$HOME/.claude/skills"
    [[ -f "$HOME/.agents/.skill-lock.json" ]] || return 0

    local ts backup
    ts="$(date +%Y%m%d_%H%M%S)"
    backup="$HOME/.claude/skills.skillpm-backup.$ts"
    warning "Detected legacy skillpm skills; migrating to apm"
    if [[ -e "$skills_dir" && ! -L "$skills_dir" ]]; then
        mv "$skills_dir" "$backup"
        info "Backed up ~/.claude/skills -> $backup"
    elif [[ -L "$skills_dir" ]]; then
        rm -f "$skills_dir"
    fi
    if [[ -d "$HOME/.agents/skills" ]]; then
        mv "$HOME/.agents/skills" "$HOME/.agents/skills.skillpm-backup.$ts"
    fi
    rm -f "$HOME/.agents/.skill-lock.json"
}

# ---- Manifest and lockfile ----

verify_apm_manifest_link() {
    local target="$HOME/.apm/apm.yml"
    local source="$DOTFILES_DIR/.apm/apm.yml"

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        return 0
    fi

    if [[ -f "$target" ]] && ! diff -q "$target" "$source" >/dev/null 2>&1; then
        local backup
        backup="${target}.detached.$(date +%Y%m%d_%H%M%S)"
        cp "$target" "$backup"
        warning "$target had detached from dotfiles and differs; saved to $backup"
        warning "Diff it before discarding — apm may have rewritten a pin"
    fi

    rm -f "$target"
    create_symlink "$source" "$target"
}

seed_apm_lockfile() {
    local source="$DOTFILES_DIR/.apm/apm.lock.yaml"
    local target="$HOME/.apm/apm.lock.yaml"

    [[ -f "$source" ]] || return 0

    # 直前の install が復路で同期しているので、通常ここは一致する。食い違うのは
    # 復路を通っていない解決 (ローカルの `apm update -g` や他マシンからの pull) が
    # ある場合で、黙って上書きすると片方が消える。apm.yml と同じく退避して知らせる。
    if [[ -f "$target" ]] && ! diff -q "$source" "$target" >/dev/null 2>&1; then
        local backup
        backup="${target}.detached.$(date +%Y%m%d_%H%M%S)"
        cp "$target" "$backup"
        warning "$target differs from dotfiles; saved to $backup before overwrite"
        warning "Diff it before discarding — an unsynced 'apm update -g' may be in there"
    fi

    cp "$source" "$target"
}

sync_apm_lockfile() {
    local source="$HOME/.apm/apm.lock.yaml"
    local dest="$DOTFILES_DIR/.apm/apm.lock.yaml"

    if [[ ! -f "$source" ]]; then
        warning "$source not found after install; nothing to sync back"
        return 0
    fi

    if diff -q "$source" "$dest" >/dev/null 2>&1; then
        return 0
    fi

    cp "$source" "$dest"
    info "apm.lock.yaml updated; review 'git diff .apm/apm.lock.yaml' for pin changes"
}

# ---- Files apm leaves behind ----

# lock の各依存が配置したパス (HOME 相対) を 1 行ずつ出す。
lock_deployed_files() {
    awk '
        /^  deployed_files:/ { inside = 1; next }
        inside && /^  - / { print substr($0, 5); next }
        { inside = 0 }
    ' "$1"
}

# install の前の lock にあって、後の lock に無い配置済みファイルを消す。
#
# 別のマシンで依存を外すと、取り込んだ lock にその依存は載っていない。
# apm は lock に無い配置済みファイルを「管理外」とみなして残すので、
# このマシンに入っていた分は誰も消さない。
prune_dropped_deployments() {
    local old_lock="$1" new_lock="$2"
    [[ -s "$old_lock" && -f "$new_lock" ]] || return 0

    local path target removed=0
    # 深いパスから消す。ファイルを消したあと、空になったディレクトリを消せる
    while IFS= read -r path; do
        # lock は外から取り込むファイル。HOME の外へ出るパスは扱わない
        case "$path" in
            "" | /* | *..*) continue ;;
        esac
        target="$HOME/$path"
        if [[ -L "$target" || -f "$target" ]]; then
            rm -f "$target"
            removed=$((removed + 1))
        elif [[ -d "$target" ]]; then
            # 本人が足したファイルが残るディレクトリは消さない
            rmdir "$target" 2>/dev/null || true
        fi
    done < <(comm -23 \
        <(lock_deployed_files "$old_lock" | LC_ALL=C sort -u) \
        <(lock_deployed_files "$new_lock" | LC_ALL=C sort -u) | LC_ALL=C sort -r)

    if [[ "$removed" -gt 0 ]]; then
        info "Removed $removed file(s) of dependencies that left the manifest"
    fi
}

# ディレクトリにあるローカルの agent の名前 (<name>.agent.md の <name>) を 1 行ずつ出す。
local_agent_names() {
    local dir="$1" file
    [[ -d "$dir" ]] || return 0
    for file in "$dir"/*.agent.md; do
        [[ -e "$file" ]] || continue
        basename "$file" .agent.md
    done
}

# 標準入力の名前について、各ハーネスへ配置済みのローカルの agent を消す。
#
# apm 0.28.0 は、ローカルの agent を lock に記録しない。一度配置したファイルを
# 「管理外」とみなすので、内容を変えても上書きせず、リポジトリから消しても残す。
# install の前に消しておき、今ある分だけを apm に置き直させる。
# 配置先のファイル名は apm の規則で、ハーネスごとに違う。
remove_deployed_local_agents() {
    local name
    while IFS= read -r name; do
        [[ -n "$name" ]] || continue
        rm -f "$HOME/.claude/agents/$name.md" \
            "$HOME/.codex/agents/$name.toml" \
            "$HOME/.copilot/agents/$name.agent.md" \
            "$HOME/.cursor/agents/$name.md"
    done
}

# ---- Install ----

install_skills() {
    info "Installing skills via apm..."

    if ! ensure_apm; then
        return 1
    fi

    cleanup_legacy_skillpm

    # dotfiles の宣言的マニフェスト (.apm/apm.yml) をグローバルの正本として配置し、
    # apm install -g で ~/.claude/skills へ展開する。
    #
    # settings.json とは違い symlink にする。copy だと apm 側の変更が dotfiles へ
    # 戻らず、~/.apm にだけ依存が増える片道の drift が起きるため。
    #
    # `apm install` 系は symlink を辿って実ファイルへ直接書く (inode 不変を実測)。
    # 引数なしなら manifest を一切書き換えないのでコメントも残る。`install <pkg>` は
    # 書き換えるためコメントを失うが、変更自体は dotfiles へ流れ git diff で追える。
    #
    # `apm update` だけは別で、atomic write のため symlink を実ファイルに置換する。
    # しかも #sha pin を「最新タグ」で上書きするので、タグが古いリポジトリでは
    # 依存が黙って巻き戻る。update 後は必ず symlink と pin の両方を確認すること。
    if [[ ! -f "$DOTFILES_DIR/.apm/apm.yml" ]]; then
        warning "$DOTFILES_DIR/.apm/apm.yml not found; skipping skills"
        return 0
    fi
    mkdir -p "$HOME/.apm"
    # `apm update` が atomic write で symlink を実ファイルに置換したあとも、ここで
    # 再リンクする。素の create_symlink だと既存実ファイルで止まって install に
    # 届かないので、退避付きの verify_apm_manifest_link を先に走らせる。
    verify_apm_manifest_link

    # 以前に写した分と今ある分の両方が、配置済みの写しを消す対象になる
    local agents
    agents="$({
        local_agent_names "$HOME/.apm/agents"
        local_agent_names "$DOTFILES_DIR/.apm/agents"
    } | LC_ALL=C sort -u)"

    # Local apm primitives live under .apm/<type>/. Mirror them into ~/.apm so
    # `apm install -g` deploys them alongside the dependency skills.
    # Clean-sync so a primitive deleted from dotfiles is also removed globally.
    #
    # dotfiles が持つのは agents だけ。hooks と scripts は、apm に hook を配らせて
    # いた頃の写しを消すために残してある (hook は .claude/settings.json が直接登録する)。
    local _dir
    for _dir in agents hooks scripts; do
        rm -rf "$HOME/.apm/$_dir"
        if [[ -d "$DOTFILES_DIR/.apm/$_dir" ]]; then
            cp -R "$DOTFILES_DIR/.apm/$_dir" "$HOME/.apm/$_dir"
        fi
    done

    # seed が上書きする前の lock。install のあと、消えた依存の配置済みファイルを割り出す
    local installed_lock status=0
    installed_lock="$(mktemp)"
    if [[ -f "$HOME/.apm/apm.lock.yaml" ]]; then
        cp "$HOME/.apm/apm.lock.yaml" "$installed_lock"
    fi

    seed_apm_lockfile

    remove_deployed_local_agents <<<"$agents"

    # No --target flag: deploy to every harness listed in apm.yml `targets`
    # (claude/codex/copilot/cursor). Rules stay cross-tool via sync-rules.sh.
    if apm install -g; then
        success "Skills and agents installed via apm (targets from apm.yml)"
        sync_apm_lockfile
        prune_dropped_deployments "$installed_lock" "$HOME/.apm/apm.lock.yaml"
    else
        # 失敗時は戻さない。途中まで書かれた lockfile を正本へ昇格させると、
        # 次のマシンがその半端な解決をそのまま再現してしまう。
        # 配置済みファイルも消さない。何が消えた依存かを、半端な lock からは決められない。
        warning "apm install reported issues; check 'apm install -g' output"
        warning "Lockfile left unsynced; dotfiles keeps the previous resolution"
        status=1
    fi
    rm -f "$installed_lock"

    # install は symlink を辿るだけだが、万一途中で実ファイル化していたら戻す。
    verify_apm_manifest_link

    return "$status"
}

# テストが source して関数単位で呼べるよう、直接実行したときだけ走らせる
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    install_skills
fi
