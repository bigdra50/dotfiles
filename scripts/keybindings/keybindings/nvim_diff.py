"""Pure parsers and diff logic for Neovim keymap JSON dumps."""

from __future__ import annotations

import json
from dataclasses import dataclass

from keybindings.schema import Keybinding


@dataclass(frozen=True)
class NvimKeymap:
    mode: str
    lhs: str
    rhs: str
    desc: str
    callback: bool


def parse_keymap_json(text: str) -> list[NvimKeymap]:
    raw_entries = json.loads(text)
    keymaps: list[NvimKeymap] = []

    for entry in raw_entries:
        keymaps.append(
            NvimKeymap(
                mode=str(entry["mode"]),
                lhs=str(entry["lhs"]),
                rhs=str(entry.get("rhs", "")),
                desc=str(entry.get("desc", "")),
                callback=bool(entry.get("callback", False)),
            )
        )

    return keymaps


def normalize_lhs(lhs: str) -> str:
    if lhs.startswith(" "):
        return f"<leader>{lhs[1:]}"
    return lhs


def is_plug_mapping(entry: NvimKeymap) -> bool:
    return entry.lhs.startswith("<Plug>")


def resolve_action(entry: NvimKeymap) -> str:
    if entry.rhs:
        return entry.rhs
    if entry.callback:
        return "(lua callback)"
    return "(no-op)"


def _identity(entry: NvimKeymap) -> tuple[str, str]:
    return (entry.mode, entry.lhs)


def exclude_builtin(
    config_maps: list[NvimKeymap],
    clean_maps: list[NvimKeymap],
) -> list[Keybinding]:
    clean_index: dict[tuple[str, str], NvimKeymap] = {}
    for entry in clean_maps:
        clean_index[_identity(entry)] = entry

    results: list[Keybinding] = []

    for entry in config_maps:
        if is_plug_mapping(entry):
            continue

        identity = _identity(entry)
        clean_entry = clean_index.get(identity)

        if clean_entry is not None and clean_entry.rhs == entry.rhs:
            continue

        if clean_entry is None:
            origin = "custom"
            change = "added"
        else:
            origin = "custom"
            change = "overridden"

        results.append(
            Keybinding(
                tool="nvim",
                context="global:all-loaded",
                mode=entry.mode,
                key=normalize_lhs(entry.lhs),
                action=resolve_action(entry),
                description=entry.desc,
                source=".config/nvim",
                origin=origin,
                change=change,
            )
        )

    return results
