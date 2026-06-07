"""Schema definitions and validation for keybinding records."""

from __future__ import annotations

from dataclasses import dataclass

ALLOWED_TOOLS: frozenset[str] = frozenset({"wezterm", "zsh", "skhd", "nvim"})
ALLOWED_ORIGINS: frozenset[str] = frozenset({"default", "custom"})
ALLOWED_CHANGES: frozenset[str] = frozenset({"unchanged", "added", "overridden"})

REQUIRED_NON_EMPTY_FIELDS: tuple[str, ...] = (
    "tool",
    "context",
    "mode",
    "key",
    "action",
    "source",
    "origin",
    "change",
)


@dataclass(frozen=True)
class Keybinding:
    tool: str
    context: str
    mode: str
    key: str
    action: str
    description: str
    source: str
    origin: str
    change: str


def to_record(kb: Keybinding) -> dict[str, str]:
    return {
        "tool": kb.tool,
        "context": kb.context,
        "mode": kb.mode,
        "key": kb.key,
        "action": kb.action,
        "description": kb.description,
        "source": kb.source,
        "origin": kb.origin,
        "change": kb.change,
    }


def validate_record(record: dict[str, str]) -> list[str]:
    errors: list[str] = []

    for field in REQUIRED_NON_EMPTY_FIELDS:
        value = record.get(field, "")
        if not isinstance(value, str) or not value.strip():
            errors.append(f"missing or empty required field: {field}")

    tool = record.get("tool", "")
    if tool and tool not in ALLOWED_TOOLS:
        errors.append(f"invalid tool: {tool!r}")

    origin = record.get("origin", "")
    if origin and origin not in ALLOWED_ORIGINS:
        errors.append(f"invalid origin: {origin!r}")

    change = record.get("change", "")
    if change and change not in ALLOWED_CHANGES:
        errors.append(f"invalid change: {change!r}")

    description = record.get("description")
    if description is not None and not isinstance(description, str):
        errors.append("description must be a string")

    return errors
