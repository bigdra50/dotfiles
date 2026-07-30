#!/usr/bin/env python3
"""Extract Zsh bindkey bindings as JSON."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from keybindings.schema import Keybinding, to_record
from keybindings.zsh_bindkey import collapse_equivalent_sequences, parse_bindkey_text


def collect_zsh_bindings(root: Path) -> list[dict[str, str]]:
    zsh_root = root / ".config" / "zsh"
    bindings: list[Keybinding] = []

    for zsh_file in sorted(zsh_root.rglob("*.zsh")):
        relative_source = zsh_file.relative_to(root).as_posix()
        text = zsh_file.read_text(encoding="utf-8")
        bindings.extend(parse_bindkey_text(text, relative_source))

    collapsed = collapse_equivalent_sequences(bindings)
    return [to_record(binding) for binding in collapsed]


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract Zsh bindkey bindings")
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()

    records = collect_zsh_bindings(args.root.resolve())
    json.dump(records, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
