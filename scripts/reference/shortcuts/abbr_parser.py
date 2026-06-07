"""Pure parsers for zsh-abbr add lines."""

from __future__ import annotations

import re

from shortcuts.alias_parser import strip_quoted_value
from shortcuts.schema import Shortcut

ABBR_ADD_PATTERN = re.compile(
    r"""^[^\S\n]*abbr\b.*?\badd\s+(?P<name>[^\s=]+)=(?P<value>.+?)\s*$""",
)


def parse_abbr_line(line: str) -> Shortcut | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None

    match = ABBR_ADD_PATTERN.match(line)
    if match is None:
        return None

    name = match.group("name")
    value = strip_quoted_value(match.group("value"))
    return Shortcut(kind="abbr", name=name, value=value, description="", source="")


def abbr_to_shortcut(abbr: Shortcut, source: str) -> Shortcut:
    return Shortcut(
        kind=abbr.kind,
        name=abbr.name,
        value=abbr.value,
        description=abbr.description,
        source=source,
    )


def parse_abbr_text(text: str, source: str) -> list[Shortcut]:
    shortcuts: list[Shortcut] = []
    for line in text.splitlines():
        parsed = parse_abbr_line(line)
        if parsed is None:
            continue
        shortcuts.append(abbr_to_shortcut(parsed, source))
    return shortcuts
