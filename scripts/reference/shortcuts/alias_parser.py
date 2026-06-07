"""Pure parsers for Zsh alias lines."""

from __future__ import annotations

import re

from shortcuts.schema import Shortcut

ALIAS_LINE_PATTERN = re.compile(
    r"""^[^\S\n]*alias(?:\s+-g)?\s+(?P<name>[^\s=]+)=(?P<value>.*)$""",
)


def strip_quoted_value(raw: str) -> str:
    trimmed = raw.strip()
    if not trimmed:
        return ""

    opening = trimmed[0]
    if opening not in {"'", '"'}:
        return trimmed.rstrip()

    index = 1
    while index < len(trimmed):
        if trimmed[index] == opening and trimmed[index - 1] != "\\":
            return trimmed[1:index]
        index += 1

    return trimmed[1:].rstrip()


def parse_alias_line(line: str) -> Shortcut | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None

    match = ALIAS_LINE_PATTERN.match(line)
    if match is None:
        return None

    name = match.group("name")
    value = strip_quoted_value(match.group("value"))
    return Shortcut(kind="alias", name=name, value=value, description="", source="")


def alias_to_shortcut(alias: Shortcut, source: str) -> Shortcut:
    return Shortcut(
        kind=alias.kind,
        name=alias.name,
        value=alias.value,
        description=alias.description,
        source=source,
    )


def parse_alias_text(text: str, source: str) -> list[Shortcut]:
    shortcuts: list[Shortcut] = []
    for line in text.splitlines():
        parsed = parse_alias_line(line)
        if parsed is None:
            continue
        shortcuts.append(alias_to_shortcut(parsed, source))
    return shortcuts
