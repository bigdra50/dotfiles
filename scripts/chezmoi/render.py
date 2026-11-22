"""モジュール定義から、chezmoi のソース（home/ 配下）の生成物を組み立てる。

実ファイルはリポジトリに元の名前のまま置き、chezmoi には「どこへ symlink を張るか」だけを渡す。
生成するのは次の 4 種類で、どれも入力はモジュール定義だけの純粋関数で決まる。

- リンク定義          symlink_<name>.tmpl。中身は作業ツリー内の実ファイルのパス
- JSON の合成         modify_private_<name>。live の JSON にリポジトリのキーを合成する
- .chezmoiignore      そのマシンで選ばれていない配置先を、chezmoi の管理から外す
- リンク表            退避と掃除のスクリプトが読む、配置先ごとの有効・無効の一覧
"""

from __future__ import annotations

import re
from collections.abc import Iterable
from dataclasses import dataclass
from enum import Enum

from manifest import Manifest, ManifestError, Merge, ancestors

HEADER = (
    "{{- /* scripts/chezmoi/gen.py が home/.chezmoidata/dotfiles.toml から生成する。"
    "手で編集しない */ -}}\n"
)
IGNORE_PATH = ".chezmoiignore"
LINK_TABLE_PATH = ".chezmoitemplates/dotfiles/link-table"

# chezmoi がソースのファイル名から属性として読み取る接頭辞と接尾辞。
# 配置先の名前がこれらで始まる（終わる）と、別の意味に解釈される。
RESERVED_PREFIXES = (
    "after_",
    "before_",
    "create_",
    "dot_",
    "empty_",
    "encrypted_",
    "exact_",
    "executable_",
    "external_",
    "literal_",
    "modify_",
    "once_",
    "onchange_",
    "private_",
    "readonly_",
    "remove_",
    "run_",
    "symlink_",
)
RESERVED_SUFFIXES = (".tmpl", ".literal", ".age", ".asc")


class Kind(Enum):
    LINK = "link"
    MERGE = "merge"
    DIR = "dir"


@dataclass(frozen=True)
class User:
    """ある配置先を必要とする条件。モジュールが有効で、platform が合うこと。"""

    module: str
    platforms: tuple[str, ...]
    module_platforms: tuple[str, ...]
    # 指定があれば、この HOME 相対のパスが既に存在するときだけ必要とする
    existing: str | None = None


# ---- ソースのファイル名 ----


def source_name(target: str, kind: Kind, private_dirs: frozenset[str]) -> str:
    """HOME 相対の配置先を、chezmoi のソース内の相対パスへ写す。"""
    parts = target.split("/")
    parents = parts if kind is Kind.DIR else parts[:-1]
    encoded = [
        ("private_" if "/".join(parts[: depth + 1]) in private_dirs else "")
        + _encode(segment)
        for depth, segment in enumerate(parents)
    ]
    if kind is Kind.DIR:
        return "/".join([*encoded, ".keep"])
    leaf = _encode(parts[-1])
    if kind is Kind.LINK:
        return "/".join([*encoded, f"symlink_{leaf}.tmpl"])
    return "/".join([*encoded, f"modify_private_{leaf}"])


def _encode(segment: str) -> str:
    if segment.startswith("."):
        # dot_ のあとは名前として読まれるので、残りに予約語があってもよい
        return "dot_" + segment[1:]
    if segment.startswith(RESERVED_PREFIXES) or segment.endswith(RESERVED_SUFFIXES):
        raise ManifestError(
            f"chezmoi が属性として読む名前は配置先にできない: {segment}"
        )
    return segment


# ---- 条件式 ----


def condition(users: Iterable[User]) -> str:
    """配置先が必要になる条件を、chezmoi のテンプレート式で返す。

    式の中の $on は有効なモジュール名の一覧、$p はそのマシンの platform。
    """
    by_module: dict[str, set[str]] = {}
    for user in users:
        by_module.setdefault(user.module, set()).add(_term(user))
    terms: list[str] = []
    for module in sorted(by_module):
        always = f'(has "{module}" $on)'
        # モジュールが有効なら常に必要、という条件が 1 つでもあれば、絞り込んだ条件は冗長
        terms.extend(
            [always] if always in by_module[module] else sorted(by_module[module])
        )
    return terms[0] if len(terms) == 1 else f"(or {' '.join(terms)})"


def _term(user: User) -> str:
    checks = [f'(has "{user.module}" $on)']
    if set(user.platforms) != set(user.module_platforms):
        names = " ".join(f'"{platform}"' for platform in user.platforms)
        checks.append(f"(has $p (list {names}))")
    if user.existing is not None:
        checks.append(f'(stat (joinPath .chezmoi.destDir "{user.existing}"))')
    return checks[0] if len(checks) == 1 else f"(and {' '.join(checks)})"


# ---- 生成物 ----


@dataclass(frozen=True)
class _Row:
    kind: Kind
    target: str
    source: str
    user: User


def _rows(manifest: Manifest) -> list[_Row]:
    rows: list[_Row] = []
    for module in manifest.modules:
        for link in module.links:
            user = User(module.name, link.platforms, module.platforms)
            rows.append(_Row(Kind.LINK, link.target, link.source, user))
        for merge in module.merges:
            user = User(
                module.name,
                merge.platforms,
                module.platforms,
                existing=None if merge.create else merge.target,
            )
            rows.append(_Row(Kind.MERGE, merge.target, merge.source, user))
        for directory in module.dirs:
            user = User(module.name, module.platforms, module.platforms)
            rows.append(_Row(Kind.DIR, directory, "-", user))
    return sorted(rows, key=lambda row: row.target)


def render(manifest: Manifest) -> dict[str, str]:
    """home/ 相対のパスから内容への対応を返す。"""
    private = frozenset(manifest.private_dirs)
    rows = _rows(manifest)
    merges = {
        merge.target: merge for module in manifest.modules for merge in module.merges
    }
    files: dict[str, str] = {}
    for row in rows:
        name = source_name(row.target, row.kind, private)
        if row.kind is Kind.LINK:
            # joinPath は OS の区切り文字で組み立てる（Windows では \）
            files[name] = f'{{{{ joinPath .chezmoi.workingTree "{row.source}" }}}}\n'
        elif row.kind is Kind.MERGE:
            files[name] = _merge_script(merges[row.target])
        else:
            files[name] = ""
    files[IGNORE_PATH] = _ignore(rows)
    files[LINK_TABLE_PATH] = _link_table(rows, manifest.retired)
    return files


def _merge_script(merge: Merge) -> str:
    keys = " ".join(f'"{key}"' for key in merge.keys)
    arguments = (
        f'"chezmoi" .chezmoi "source" "{merge.source}" '
        f'"keys" (list{" " + keys if keys else ""}) "create" {str(merge.create).lower()}'
    )
    return (
        "{{- /* chezmoi:modify-template */ -}}\n"
        + HEADER
        + f'{{{{- includeTemplate "dotfiles/json-merge" (dict {arguments}) -}}}}\n'
    )


def _preamble() -> str:
    return (
        HEADER
        + '{{- $on := includeTemplate "dotfiles/enabled" . | fromJson -}}\n'
        + '{{- $p := includeTemplate "dotfiles/platform" . -}}\n'
    )


def _ignore(rows: list[_Row]) -> str:
    """必要とするものが無い配置先と親ディレクトリを、管理の対象から外す。"""
    users: dict[str, list[User]] = {}
    for row in rows:
        for path in (*ancestors(row.target), row.target):
            users.setdefault(path, []).append(row.user)
    blocks = [
        f"{{{{ if not {condition(users[path])} }}}}\n{path}\n{{{{ end }}}}\n"
        for path in sorted(users)
    ]
    scripts = (
        "{{- /* スクリプトは OS が実行できる形式だけを残す */ -}}\n"
        '{{ if eq .chezmoi.os "windows" }}\n'
        ".chezmoiscripts/*.sh\n"
        "{{ else }}\n"
        ".chezmoiscripts/*.ps1\n"
        "{{ end }}\n"
    )
    return _preamble() + "\n" + "".join(blocks) + scripts


def _link_table(rows: list[_Row], retired: tuple[str, ...]) -> str:
    """配置先ごとに `状態<TAB>種類<TAB>配置先<TAB>ソース` を 1 行で出すテンプレート。

    状態は、そのマシンで有効なら on、無効なら off。
    retired は以前の配置先で、常に off。
    """
    lines = {
        row.target: "\t".join(
            [_state(row.user), row.kind.value, row.target, row.source]
        )
        for row in rows
        if row.kind is not Kind.DIR
    }
    lines.update({target: f"off\tretired\t{target}\t-" for target in retired})
    return _preamble() + "\n".join(lines[target] for target in sorted(lines)) + "\n"


def _state(user: User) -> str:
    return f"{{{{ if {condition([user])} }}}}on{{{{ else }}}}off{{{{ end }}}}"


# ---- 生成物かどうか ----


def is_generated(path: str) -> bool:
    """home/ 相対のパスが、この生成器の出力か。古い生成物を消すときの判定に使う。"""
    if path in (IGNORE_PATH, LINK_TABLE_PATH):
        return True
    if path.startswith((".chezmoiscripts/", ".chezmoitemplates/", ".chezmoidata/")):
        return False
    name = path.rsplit("/", 1)[-1]
    return (
        (name.startswith("symlink_") and name.endswith(".tmpl"))
        or name.startswith("modify_")
        or name == ".keep"
    )


_PRESETS_LINE = re.compile(r'\$presets\s*:=\s*list((?:\s+"[^"]+")+)')


def presets_in_config_template(template: str) -> tuple[str, ...]:
    """設定テンプレート（.chezmoi.toml.tmpl）が選択肢として挙げるプリセット名。

    chezmoi は設定テンプレートを .chezmoidata より先に評価するので、名前を二重に持つ。
    """
    match = _PRESETS_LINE.search(template)
    if match is None:
        return ()
    return tuple(sorted(re.findall(r'"([^"]+)"', match.group(1))))
