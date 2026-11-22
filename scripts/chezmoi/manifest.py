"""dotfiles のモジュール定義の型と、定義が満たすべき不変条件。

正本は home/.chezmoidata/dotfiles.toml。
ここでは TOML を型へ変換し（parse_manifest）、型の上で検査と選択の計算をする。
chezmoi 側のテンプレート（home/.chezmoitemplates/dotfiles/enabled）は enabled_modules と同じ計算をする。
"""

from __future__ import annotations

import sys
import tomllib
from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any


class ManifestError(ValueError):
    """定義の形が読めない、またはマシンの選択が定義と合わない。"""


@dataclass(frozen=True)
class Link:
    """HOME 相対の target に、リポジトリ相対の source への symlink を置く。"""

    target: str
    source: str
    platforms: tuple[str, ...]


@dataclass(frozen=True)
class Merge:
    """リポジトリの JSON を、アプリが書き換える live の JSON へ合成する。

    keys が空なら source の全キーを合成する。
    create が偽なら、live のファイルが既にあるときだけ合成する。
    """

    target: str
    source: str
    platforms: tuple[str, ...]
    keys: tuple[str, ...] = ()
    create: bool = True


@dataclass(frozen=True)
class Module:
    name: str
    platforms: tuple[str, ...]
    links: tuple[Link, ...] = ()
    merges: tuple[Merge, ...] = ()
    # 中身を管理しない空のディレクトリ（HOME 相対）
    dirs: tuple[str, ...] = ()


@dataclass(frozen=True)
class Manifest:
    platforms: tuple[str, ...]
    private_dirs: tuple[str, ...]
    retired: tuple[str, ...]
    presets: Mapping[str, tuple[str, ...]]
    modules: tuple[Module, ...]

    def module(self, name: str) -> Module | None:
        return next((module for module in self.modules if module.name == name), None)


@dataclass(frozen=True)
class Machine:
    """~/.config/chezmoi/chezmoi.toml の [data.machine] に当たる、マシンごとの選択。"""

    platform: str
    preset: str
    with_: tuple[str, ...] = ()
    without: tuple[str, ...] = ()


@dataclass(frozen=True)
class Placements:
    """あるマシンで chezmoi が置くもの。"""

    links: Mapping[str, str]
    merges: tuple[Merge, ...]
    dirs: frozenset[str]
    # 空の HOME に適用したあとに存在するパス（親ディレクトリを含む）
    entries: frozenset[str]


# ---- TOML から型へ ----


def load_manifest(path: Path) -> Manifest:
    with path.open("rb") as file:
        return parse_manifest(tomllib.load(file))


def parse_manifest(data: Mapping[str, Any]) -> Manifest:
    root = _table(data.get("dotfiles"), "dotfiles")
    _only(
        root, {"platforms", "private_dirs", "retired", "presets", "modules"}, "dotfiles"
    )
    presets = _table(root.get("presets", {}), "dotfiles.presets")
    modules = _table(root.get("modules", {}), "dotfiles.modules")
    return Manifest(
        platforms=_strings(root.get("platforms"), "dotfiles.platforms"),
        private_dirs=_strings(root.get("private_dirs", []), "dotfiles.private_dirs"),
        retired=_strings(root.get("retired", []), "dotfiles.retired"),
        presets={
            name: _strings(names, f"dotfiles.presets.{name}")
            for name, names in presets.items()
        },
        modules=tuple(_module(name, body) for name, body in modules.items()),
    )


def _module(name: str, body: Any) -> Module:
    where = f"dotfiles.modules.{name}"
    table = _table(body, where)
    _only(table, {"description", "platforms", "links", "merges", "dirs"}, where)
    platforms = _strings(table.get("platforms"), f"{where}.platforms")
    links: list[Link] = []
    for index, item in enumerate(_list(table.get("links", []), f"{where}.links")):
        entry = _table(item, f"{where}.links[{index}]")
        _only(
            entry, {"path", "target", "source", "platforms"}, f"{where}.links[{index}]"
        )
        target, source = _paths(entry, f"{where}.links[{index}]")
        links.append(Link(target, source, _entry_platforms(entry, platforms, where)))
    merges: list[Merge] = []
    for index, item in enumerate(_list(table.get("merges", []), f"{where}.merges")):
        entry = _table(item, f"{where}.merges[{index}]")
        _only(
            entry,
            {"path", "target", "source", "platforms", "keys", "create"},
            f"{where}.merges[{index}]",
        )
        target, source = _paths(entry, f"{where}.merges[{index}]")
        create = entry.get("create", True)
        if not isinstance(create, bool):
            raise ManifestError(f"{where}.merges[{index}].create は真偽値")
        merges.append(
            Merge(
                target,
                source,
                _entry_platforms(entry, platforms, where),
                keys=_strings(entry.get("keys", []), f"{where}.merges[{index}].keys"),
                create=create,
            )
        )
    return Module(
        name=name,
        platforms=platforms,
        links=tuple(links),
        merges=tuple(merges),
        dirs=_strings(table.get("dirs", []), f"{where}.dirs"),
    )


def _paths(entry: Mapping[str, Any], where: str) -> tuple[str, str]:
    has_path = "path" in entry
    has_pair = "target" in entry or "source" in entry
    if has_path == has_pair:
        raise ManifestError(f"{where}: path か、target と source の組のどちらかを書く")
    if has_path:
        path = _string(entry["path"], f"{where}.path")
        return path, path
    if "target" not in entry or "source" not in entry:
        raise ManifestError(f"{where}: target と source は両方書く")
    return (
        _string(entry["target"], f"{where}.target"),
        _string(entry["source"], f"{where}.source"),
    )


def _entry_platforms(
    entry: Mapping[str, Any], module_platforms: tuple[str, ...], where: str
) -> tuple[str, ...]:
    if "platforms" not in entry:
        return module_platforms
    return _strings(entry["platforms"], f"{where}.platforms")


def _table(value: Any, where: str) -> Mapping[str, Any]:
    if not isinstance(value, Mapping):
        raise ManifestError(f"{where} はテーブル")
    return value


def _list(value: Any, where: str) -> list[Any]:
    if not isinstance(value, list):
        raise ManifestError(f"{where} は配列")
    return value


def _string(value: Any, where: str) -> str:
    if not isinstance(value, str):
        raise ManifestError(f"{where} は文字列")
    return value


def _strings(value: Any, where: str) -> tuple[str, ...]:
    return tuple(
        _string(item, f"{where}[{index}]")
        for index, item in enumerate(_list(value, where))
    )


def _only(table: Mapping[str, Any], allowed: set[str], where: str) -> None:
    unknown = sorted(set(table) - allowed)
    if unknown:
        raise ManifestError(f"{where}: 未知のキー: {', '.join(unknown)}")


# ---- 不変条件 ----


def is_normalized(path: str) -> bool:
    """HOME やリポジトリの外へ出ない、正規化済みの相対パスか。"""
    if not path or "\\" in path:
        return False
    pure = PurePosixPath(path)
    return not pure.is_absolute() and ".." not in pure.parts and pure.as_posix() == path


def ancestors(path: str) -> tuple[str, ...]:
    """`a/b/c` の親を浅い順に返す（`a`, `a/b`）。"""
    parts = path.split("/")
    return tuple("/".join(parts[:depth]) for depth in range(1, len(parts)))


def check_manifest(
    manifest: Manifest, source_exists: Callable[[str], bool]
) -> list[str]:
    """定義の違反を列挙する。空なら違反なし。

    source_exists はリポジトリ相対のパスが実在するかを返す（ファイルシステムへの依存はここだけ）。
    """
    violations: list[str] = []
    known = set(manifest.platforms)
    placed: dict[str, set[str]] = {}
    link_targets: set[str] = set()
    all_targets: set[str] = set()

    for module in manifest.modules:
        for platform in module.platforms:
            if platform not in known:
                violations.append(f"{module.name}: 未知の platform: {platform}")
        entries: tuple[Link | Merge, ...] = (*module.links, *module.merges)
        for entry in entries:
            bad = [
                path for path in (entry.target, entry.source) if not is_normalized(path)
            ]
            for path in bad:
                violations.append(f"{module.name}: 正規化されていないパス: {path!r}")
            if bad:
                continue
            outside = [p for p in entry.platforms if p not in module.platforms]
            if outside:
                violations.append(
                    f"{module.name}: {entry.target} の platform がモジュールの範囲外: "
                    f"{', '.join(outside)}"
                )
            if not source_exists(entry.source):
                violations.append(f"{module.name}: source が無い: {entry.source}")
            placed.setdefault(entry.target, set()).add(module.name)
            all_targets.add(entry.target)
            if isinstance(entry, Link):
                link_targets.add(entry.target)
        for directory in module.dirs:
            if not is_normalized(directory):
                violations.append(
                    f"{module.name}: 正規化されていないパス: {directory!r}"
                )
                continue
            placed.setdefault(directory, set()).add(module.name)
            all_targets.add(directory)

    for target, owners in sorted(placed.items()):
        if len(owners) > 1:
            violations.append(f"配置先が重複: {target} ({', '.join(sorted(owners))})")
    # symlink の内側には別の配置先を置けない（置くとリポジトリの中へ書き込む）
    for target in sorted(all_targets):
        for parent in ancestors(target):
            if parent in link_targets:
                violations.append(f"配置先が入れ子: {target} は {parent} の内側")

    names = {module.name for module in manifest.modules}
    for preset, members in manifest.presets.items():
        for name in members:
            if name not in names:
                violations.append(f"preset {preset}: 未定義のモジュール: {name}")

    for path in manifest.retired:
        if not is_normalized(path):
            violations.append(f"retired: 正規化されていないパス: {path!r}")
        elif path in all_targets:
            violations.append(f"retired と配置先が重複: {path}")

    parents = {parent for target in all_targets for parent in ancestors(target)}
    for path in manifest.private_dirs:
        if path not in parents and path not in all_targets:
            violations.append(f"private_dirs が配置先の親ではない: {path}")

    return violations


# ---- マシンごとの選択 ----


def enabled_modules(manifest: Manifest, machine: Machine) -> frozenset[str]:
    """(preset + with - without) のうち、そのマシンの platform に対応するモジュール。

    プリセットの非対応モジュールは黙って外す。
    with と without は本人が名指ししたものなので、定義と合わなければ誤りとして止める。
    """
    if machine.platform not in manifest.platforms:
        raise ManifestError(f"未対応の platform: {machine.platform}")
    if machine.preset not in manifest.presets:
        raise ManifestError(f"未定義の preset: {machine.preset}")
    for name in (*machine.with_, *machine.without):
        if manifest.module(name) is None:
            raise ManifestError(f"未定義のモジュール: {name}")
    for name in machine.with_:
        module = manifest.module(name)
        if module is not None and machine.platform not in module.platforms:
            raise ManifestError(f"platform に対応しない: {name} ({machine.platform})")

    wanted = (*manifest.presets[machine.preset], *machine.with_)
    return frozenset(
        module.name
        for module in manifest.modules
        if module.name in wanted
        and module.name not in machine.without
        and machine.platform in module.platforms
    )


def placements(manifest: Manifest, machine: Machine) -> Placements:
    enabled = enabled_modules(manifest, machine)
    modules = [module for module in manifest.modules if module.name in enabled]
    links = {
        link.target: link.source
        for module in modules
        for link in module.links
        if machine.platform in link.platforms
    }
    merges = tuple(
        merge
        for module in modules
        for merge in module.merges
        if machine.platform in merge.platforms
    )
    dirs = frozenset(directory for module in modules for directory in module.dirs)
    return Placements(
        links=links,
        merges=merges,
        dirs=dirs,
        entries=_with_ancestors(
            [*links, *dirs, *(merge.target for merge in merges if merge.create)]
        ),
    )


def _with_ancestors(paths: Iterable[str]) -> frozenset[str]:
    found: set[str] = set()
    for path in paths:
        found.add(path)
        found.update(ancestors(path))
    return frozenset(found)


def host_platform() -> str:
    """この Python が動いているマシンの platform（scripts/lib.sh の detect_platform と同じ語彙）。"""
    if sys.platform == "darwin":
        return "macos"
    if sys.platform == "win32":
        return "windows"
    if sys.platform.startswith("linux"):
        try:
            version = Path("/proc/version").read_text(encoding="utf-8")
        except OSError:
            version = ""
        return "wsl" if "microsoft" in version.lower() else "linux"
    raise ManifestError(f"未対応の platform: {sys.platform}")
