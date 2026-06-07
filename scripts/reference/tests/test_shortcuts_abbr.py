"""Tests for zsh-abbr parsing."""

from __future__ import annotations

import unittest
from pathlib import Path

from shortcuts.abbr_parser import parse_abbr_line, parse_abbr_text

FIXTURES = Path(__file__).parent / "fixtures"


class TestShortcutsAbbr(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_text = (FIXTURES / "shortcuts-abbr.zsh").read_text(
            encoding="utf-8"
        )
        self.source = ".config/zsh/plugins/abbr.zsh"

    def test_parse_abbr_line_parses_flags_and_quoted_value(self) -> None:
        parsed = parse_abbr_line('abbr -S -q add cp="cp -r"')
        assert parsed is not None
        self.assertEqual(parsed.name, "cp")
        self.assertEqual(parsed.value, "cp -r")
        self.assertEqual(parsed.kind, "abbr")

    def test_parse_abbr_line_parses_unquoted_value(self) -> None:
        parsed = parse_abbr_line("abbr add mkdir=mkdir -p")
        assert parsed is not None
        self.assertEqual(parsed.name, "mkdir")
        self.assertEqual(parsed.value, "mkdir -p")

    def test_parse_abbr_text_fixture_count(self) -> None:
        shortcuts = parse_abbr_text(self.fixture_text, self.source)
        self.assertEqual(len(shortcuts), 3)
        self.assertEqual(
            [shortcut.name for shortcut in shortcuts], ["cp", "mkdir", "g"]
        )


if __name__ == "__main__":
    unittest.main()
