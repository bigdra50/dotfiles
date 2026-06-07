"""Pure parsers for Zsh function definitions."""

from __future__ import annotations

import re

from shortcuts.schema import Shortcut

FUNCTION_NAME_PATTERN = re.compile(
    r"""^[^\S\n]*([a-zA-Z_][a-zA-Z0-9_-]*)\s*\(\)\s*\{""",
)
FUNCTION_KEYWORD_PATTERN = re.compile(
    r"""^[^\S\n]*function\s+([a-zA-Z_][a-zA-Z0-9_-]*)\s*(?:\(\))?\s*\{""",
)


def strip_comment_text(line: str) -> str:
    stripped = line.strip()
    if not stripped.startswith("#"):
        return ""
    body = stripped[1:]
    if body.startswith(" "):
        body = body[1:]
    return body


def collect_preceding_comment_description(lines: list[str], line_index: int) -> str:
    comment_lines: list[str] = []
    cursor = line_index - 1

    while cursor >= 0:
        stripped = lines[cursor].strip()
        if not stripped:
            break
        if not stripped.startswith("#"):
            break
        comment_lines.insert(0, strip_comment_text(lines[cursor]))
        cursor -= 1

    return "\n".join(comment_lines)


def parse_function_name(line: str) -> str | None:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return None

    name_match = FUNCTION_NAME_PATTERN.match(line)
    if name_match is not None:
        return name_match.group(1)

    keyword_match = FUNCTION_KEYWORD_PATTERN.match(line)
    if keyword_match is not None:
        return keyword_match.group(1)

    return None


def parse_function_text(text: str, source: str) -> list[Shortcut]:
    lines = text.splitlines()
    shortcuts: list[Shortcut] = []

    for index, line in enumerate(lines):
        name = parse_function_name(line)
        if name is None:
            continue

        description = collect_preceding_comment_description(lines, index)
        shortcuts.append(
            Shortcut(
                kind="function",
                name=name,
                value="",
                description=description,
                source=source,
            ),
        )

    return shortcuts
