"""Pure parsers for Zsh bindkey lines."""

from __future__ import annotations

import re
from dataclasses import dataclass

from keybindings.schema import Keybinding

BINDKEY_KEYMAP_PATTERN = re.compile(r"^bindkey\s+-v\s*$")
BINDKEY_UNSUPPORTED_OPTION_PATTERN = re.compile(r"^bindkey\s+-")
BINDKEY_QUOTED_PATTERN = re.compile(
    r"""^bindkey\s+(?P<quote>['"])(?P<seq>(?:\\.|(?!\1).)*)\1\s+(?P<widget>\S+)\s*$"""
)


@dataclass(frozen=True)
class ZshBindkey:
    sequence: str
    widget: str


def parse_bindkey_line(line: str) -> ZshBindkey | None:
    """Parse a single bindkey line.

    Returns None for ``bindkey -v`` (vi keymap switch).

    Raises ValueError for unsupported grammar such as ``bindkey -M keymap``.
    Future grammar additions require adding tests.
    """
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None

    if not stripped.startswith("bindkey"):
        return None

    if BINDKEY_KEYMAP_PATTERN.match(stripped):
        return None

    if BINDKEY_UNSUPPORTED_OPTION_PATTERN.match(stripped):
        raise ValueError(f"unsupported bindkey option syntax: {stripped!r}")

    quoted_match = BINDKEY_QUOTED_PATTERN.match(stripped)
    if quoted_match is None:
        raise ValueError(f"unsupported bindkey syntax: {stripped!r}")

    sequence = quoted_match.group("seq")
    widget = quoted_match.group("widget")
    return ZshBindkey(sequence=sequence, widget=widget)


def humanize_key_sequence(seq: str) -> str:
    if seq == " ":
        return "Space"

    escape_map = {
        r"\e[A": "Up",
        r"\eOA": "Up",
        r"\e[B": "Down",
        r"\eOB": "Down",
    }
    if seq in escape_map:
        return escape_map[seq]

    if seq.startswith("^") and len(seq) >= 2:
        if seq == "^ ":
            return "Ctrl+Space"
        if seq == "^]":
            return "Ctrl+]"
        if seq == "^\\":
            return "Ctrl+\\"
        if len(seq) == 2:
            control_char = seq[1]
            return f"Ctrl+{control_char.upper()}"
        if len(seq) == 3 and seq[1].isupper() and seq[2].islower():
            return f"Ctrl+{seq[1]} {seq[2]}"

    return seq


def bindkey_to_keybinding(bindkey: ZshBindkey, source_path: str) -> Keybinding:
    return Keybinding(
        tool="zsh",
        context="zle",
        mode="viins",
        key=humanize_key_sequence(bindkey.sequence),
        action=bindkey.widget,
        description="",
        source=source_path,
        origin="custom",
        change="added",
    )


def parse_bindkey_text(text: str, source_path: str) -> list[Keybinding]:
    bindings: list[Keybinding] = []
    for line in text.splitlines():
        if line.strip().startswith("#"):
            continue
        parsed = parse_bindkey_line(line)
        if parsed is None:
            continue
        bindings.append(bindkey_to_keybinding(parsed, source_path))
    return bindings


def collapse_equivalent_sequences(bindings: list[Keybinding]) -> list[Keybinding]:
    seen_pairs: set[tuple[str, str]] = set()
    collapsed: list[Keybinding] = []

    for binding in bindings:
        pair = (binding.key, binding.action)
        if pair in seen_pairs:
            continue
        seen_pairs.add(pair)
        collapsed.append(binding)

    return collapsed
