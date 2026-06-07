"""Tests for Zsh alias parsing."""

from __future__ import annotations

import unittest
from pathlib import Path

from shortcuts.alias_parser import parse_alias_line, parse_alias_text

FIXTURES = Path(__file__).parent / "fixtures"


class TestShortcutsAlias(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_text = (FIXTURES / "shortcuts-alias.zsh").read_text(
            encoding="utf-8"
        )
        self.source = ".config/zsh/fixtures/shortcuts-alias.zsh"

    def test_parse_alias_line_skips_commented_alias(self) -> None:
        self.assertIsNone(parse_alias_line("#alias ls='ls -la'"))

    def test_parse_alias_line_parses_single_quoted_value(self) -> None:
        parsed = parse_alias_line("alias quoted_single='echo one'")
        assert parsed is not None
        self.assertEqual(parsed.name, "quoted_single")
        self.assertEqual(parsed.value, "echo one")

    def test_parse_alias_line_parses_double_quoted_value(self) -> None:
        parsed = parse_alias_line('alias quoted_double="echo two"')
        assert parsed is not None
        self.assertEqual(parsed.value, "echo two")

    def test_parse_alias_line_parses_unquoted_value(self) -> None:
        parsed = parse_alias_line("alias .2=cd ../..")
        assert parsed is not None
        self.assertEqual(parsed.name, ".2")
        self.assertEqual(parsed.value, "cd ../..")

    def test_parse_alias_line_parses_global_alias(self) -> None:
        parsed = parse_alias_line("alias -g L='|bat --style=plain'")
        assert parsed is not None
        self.assertEqual(parsed.name, "L")
        self.assertEqual(parsed.value, "|bat --style=plain")

    def test_parse_alias_text_fixture_includes_case_block_aliases(self) -> None:
        shortcuts = parse_alias_text(self.fixture_text, self.source)
        names = [shortcut.name for shortcut in shortcuts]
        self.assertEqual(len(shortcuts), 6)
        self.assertIn("c", names)
        self.assertIn("exp", names)
        self.assertNotIn("ls", names)

    def test_parse_alias_text_fixture_sets_source(self) -> None:
        shortcuts = parse_alias_text(self.fixture_text, self.source)
        self.assertTrue(all(shortcut.source == self.source for shortcut in shortcuts))
        self.assertTrue(all(shortcut.kind == "alias" for shortcut in shortcuts))


if __name__ == "__main__":
    unittest.main()
