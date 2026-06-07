"""Pure parsers for skhd configuration."""

from __future__ import annotations

import re

from keybindings.schema import Keybinding

COMMENT_PATTERN = re.compile(r"^\s*#\s*(.+?)\s*$")
BINDING_PATTERN = re.compile(
    r"^\s*(?P<mods>.+?)\s+-\s+(?P<key>\S+)\s*:\s*(?P<command>.+?)\s*$"
)


def normalize_skhd_mods(mods: str) -> str:
    parts = [part.strip() for part in mods.split("+")]
    return "+".join(parts)


def parse_skhdrc(text: str) -> list[Keybinding]:
    bindings: list[Keybinding] = []
    current_context = "uncategorized"

    for line_number, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if not stripped:
            continue

        comment_match = COMMENT_PATTERN.match(line)
        if comment_match is not None:
            current_context = comment_match.group(1)
            continue

        binding_match = BINDING_PATTERN.match(line)
        if binding_match is None:
            raise ValueError(
                f"invalid skhd binding syntax at line {line_number}: {line!r}"
            )

        mods = normalize_skhd_mods(binding_match.group("mods"))
        key = binding_match.group("key")
        command = binding_match.group("command")

        bindings.append(
            Keybinding(
                tool="skhd",
                context=current_context,
                mode=mods,
                key=key,
                action=command,
                description="",
                source=".skhdrc",
                origin="custom",
                change="added",
            )
        )

    return bindings
