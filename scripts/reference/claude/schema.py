"""Schema definitions for Claude Code asset records."""

from __future__ import annotations

from dataclasses import dataclass

ALLOWED_TYPES: frozenset[str] = frozenset({"agent", "command", "rule"})


@dataclass(frozen=True)
class ClaudeAsset:
    type: str
    name: str
    description: str
    model: str
    source: str


def collapse_whitespace(text: str) -> str:
    """Collapse newlines and repeated whitespace to single spaces."""
    return " ".join(text.split())


def to_record(asset: ClaudeAsset) -> dict[str, str]:
    return {
        "type": asset.type,
        "name": asset.name,
        "description": collapse_whitespace(asset.description),
        "model": asset.model,
        "source": asset.source,
    }
