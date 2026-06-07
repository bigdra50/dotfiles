"""Hand-rolled YAML frontmatter parser for Claude Code markdown assets."""

from __future__ import annotations


def parse_frontmatter(text: str) -> dict[str, str] | None:
    """Parse a leading ``---`` frontmatter block into string key/value pairs."""
    if not text.startswith("---\n"):
        return None

    lines = text.split("\n")
    close_index: int | None = None
    for index in range(1, len(lines)):
        if lines[index] == "---":
            close_index = index
            break

    if close_index is None:
        return None

    return _parse_frontmatter_lines(lines[1:close_index])


def _parse_frontmatter_lines(lines: list[str]) -> dict[str, str]:
    result: dict[str, str] = {}
    index = 0
    while index < len(lines):
        line = lines[index]
        if not line.strip():
            index += 1
            continue

        if ":" not in line:
            index += 1
            continue

        key, _, remainder = line.partition(":")
        key = key.strip()
        value = remainder.strip()

        if value == "|":
            block_lines: list[str] = []
            index += 1
            while index < len(lines):
                continuation = lines[index]
                if continuation and not continuation[0].isspace():
                    break
                if continuation.strip():
                    block_lines.append(continuation.strip())
                index += 1
            result[key] = " ".join(block_lines)
            continue

        if not value:
            index += 1
            while index < len(lines):
                continuation = lines[index]
                if continuation and not continuation[0].isspace():
                    break
                index += 1
            continue

        result[key] = value
        index += 1

    return result
