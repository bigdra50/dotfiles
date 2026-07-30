#!/usr/bin/env python3
"""Extract Zsh aliases, abbreviations, and functions as JSON."""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Callable
from pathlib import Path

from shortcuts.abbr_parser import parse_abbr_text
from shortcuts.alias_parser import parse_alias_text
from shortcuts.function_parser import parse_function_text
from shortcuts.schema import Shortcut, to_record

ParseTextFn = Callable[[str, str], list[Shortcut]]


def collect_alias_files(zsh_root: Path) -> list[Path]:
    plugin_dir = zsh_root / "plugins"
    files = [zsh_root / "alias.zsh"]
    if plugin_dir.is_dir():
        files.extend(sorted(plugin_dir.glob("*.zsh")))
    return files


def collect_function_files(zsh_root: Path) -> list[Path]:
    plugin_dir = zsh_root / "plugins"
    files = [
        zsh_root / "func.zsh",
        zsh_root / "history.zsh",
        zsh_root / "interface.zsh",
    ]
    if plugin_dir.is_dir():
        files.extend(sorted(plugin_dir.glob("*.zsh")))
    return files


def read_shortcuts_from_file(
    path: Path,
    root: Path,
    parse_text: ParseTextFn,
) -> list[Shortcut]:
    if not path.is_file():
        return []

    relative_source = path.relative_to(root).as_posix()
    text = path.read_text(encoding="utf-8")
    return parse_text(text, relative_source)


def collect_shortcuts(root: Path) -> list[dict[str, str]]:
    zsh_root = root / ".config" / "zsh"
    shortcuts: list[Shortcut] = []

    for alias_file in collect_alias_files(zsh_root):
        shortcuts.extend(read_shortcuts_from_file(alias_file, root, parse_alias_text))

    abbr_file = zsh_root / "plugins" / "abbr.zsh"
    shortcuts.extend(read_shortcuts_from_file(abbr_file, root, parse_abbr_text))

    for function_file in collect_function_files(zsh_root):
        shortcuts.extend(
            read_shortcuts_from_file(function_file, root, parse_function_text)
        )

    return [to_record(shortcut) for shortcut in shortcuts]


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Zsh shortcuts")
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()

    records = collect_shortcuts(args.root.resolve())
    json.dump(records, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
