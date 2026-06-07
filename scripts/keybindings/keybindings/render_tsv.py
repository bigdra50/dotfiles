"""Pure TSV rendering for fzf keybinding search."""

from __future__ import annotations


def sanitize_tsv_field(value: str) -> str:
    """Replace tab and newline characters with a single space."""
    return value.replace("\t", " ").replace("\n", " ").replace("\r", " ")


def render_fzf_tsv(records: list[dict[str, str]]) -> str:
    """Render keybinding records as tab-separated lines for fzf."""
    lines: list[str] = []
    for record in records:
        fields = [
            sanitize_tsv_field(record.get("tool", "")),
            sanitize_tsv_field(record.get("mode", "")),
            sanitize_tsv_field(record.get("key", "")),
            sanitize_tsv_field(record.get("action", "")),
            sanitize_tsv_field(record.get("description", "")),
            sanitize_tsv_field(record.get("origin", "")),
            sanitize_tsv_field(record.get("change", "")),
            sanitize_tsv_field(record.get("source", "")),
        ]
        lines.append("\t".join(fields))
    return "\n".join(lines) + ("\n" if lines else "")
