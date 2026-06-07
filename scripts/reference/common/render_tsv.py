"""Generic TSV rendering for fzf reference search."""

from __future__ import annotations

from collections.abc import Sequence


def sanitize_tsv_field(value: str) -> str:
    """Replace tab and newline characters with a single space."""
    return value.replace("\t", " ").replace("\n", " ").replace("\r", " ")


def render_tsv(records: list[dict[str, str]], fields: Sequence[str]) -> str:
    """Render records as tab-separated lines using the given field order."""
    lines: list[str] = []
    for record in records:
        cells = [sanitize_tsv_field(record.get(field, "")) for field in fields]
        lines.append("\t".join(cells))
    return "\n".join(lines) + ("\n" if lines else "")
