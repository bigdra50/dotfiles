"""Tests for the generic fzf TSV renderer."""

from __future__ import annotations

import unittest

from common.render_tsv import render_tsv, sanitize_tsv_field
from keybindings.page import TSV_FIELDS


def _sample_record(**overrides: str) -> dict[str, str]:
    base: dict[str, str] = {
        "tool": "wezterm",
        "context": "global",
        "mode": "normal",
        "key": "Ctrl+Shift+C",
        "action": "CopyTo",
        "description": "copy",
        "source": ".wezterm.lua",
        "origin": "custom",
        "change": "added",
    }
    base.update(overrides)
    return base


class TestRenderTsv(unittest.TestCase):
    def test_column_order_follows_fields(self) -> None:
        output = render_tsv([_sample_record()], TSV_FIELDS)
        fields = output.rstrip("\n").split("\t")
        self.assertEqual(len(fields), 8)
        self.assertEqual(fields[0], "wezterm")
        self.assertEqual(fields[1], "normal")
        self.assertEqual(fields[2], "Ctrl+Shift+C")
        self.assertEqual(fields[3], "CopyTo")
        self.assertEqual(fields[4], "copy")
        self.assertEqual(fields[5], "custom")
        self.assertEqual(fields[6], "added")
        self.assertEqual(fields[7], ".wezterm.lua")

    def test_tab_and_newline_sanitization(self) -> None:
        dirty = "line1\nline2\tcol"
        self.assertEqual(sanitize_tsv_field(dirty), "line1 line2 col")
        record = _sample_record(description=dirty, action="act\ttab")
        fields = render_tsv([record], TSV_FIELDS).rstrip("\n").split("\t")
        self.assertEqual(len(fields), 8)
        self.assertEqual(fields[3], "act tab")
        self.assertEqual(fields[4], "line1 line2 col")

    def test_arbitrary_field_subset(self) -> None:
        output = render_tsv([_sample_record()], ("key", "action"))
        fields = output.rstrip("\n").split("\t")
        self.assertEqual(fields, ["Ctrl+Shift+C", "CopyTo"])

    def test_line_count_matches_record_count(self) -> None:
        records = [_sample_record(key="a"), _sample_record(key="b")]
        output = render_tsv(records, TSV_FIELDS)
        lines = [line for line in output.split("\n") if line]
        self.assertEqual(len(lines), 2)


if __name__ == "__main__":
    unittest.main()
