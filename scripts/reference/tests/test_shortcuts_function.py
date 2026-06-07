"""Tests for Zsh function parsing."""

from __future__ import annotations

import unittest
from pathlib import Path

from shortcuts.function_parser import parse_function_name, parse_function_text

FIXTURES = Path(__file__).parent / "fixtures"


class TestShortcutsFunction(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_text = (FIXTURES / "shortcuts-function.zsh").read_text(
            encoding="utf-8"
        )
        self.source = ".config/zsh/fixtures/shortcuts-function.zsh"

    def test_parse_function_name_matches_name_paren_form(self) -> None:
        self.assertEqual(parse_function_name("ch() { cheat $* | bat }"), "ch")

    def test_parse_function_name_matches_function_keyword_form(self) -> None:
        self.assertEqual(
            parse_function_name("function history-all { history -E 1 }"), "history-all"
        )

    def test_parse_function_text_fixture_uses_preceding_comment_description(
        self,
    ) -> None:
        shortcuts = parse_function_text(self.fixture_text, self.source)
        ch = next(shortcut for shortcut in shortcuts if shortcut.name == "ch")
        self.assertEqual(ch.description, "helper for cheat sheets")

    def test_parse_function_text_fixture_uses_empty_description_without_comment(
        self,
    ) -> None:
        shortcuts = parse_function_text(self.fixture_text, self.source)
        pop = next(shortcut for shortcut in shortcuts if shortcut.name == "pop")
        self.assertEqual(pop.description, "")

    def test_parse_function_text_fixture_count(self) -> None:
        shortcuts = parse_function_text(self.fixture_text, self.source)
        self.assertEqual(len(shortcuts), 4)
        self.assertEqual(
            [shortcut.name for shortcut in shortcuts],
            ["ch", "pop", "history-all", "ghq-fzf"],
        )

    def test_parse_function_text_keeps_duplicate_names_across_sources(self) -> None:
        first = parse_function_text("ch() { cheat $* }", ".config/zsh/plugins/bat.zsh")
        second = parse_function_text(
            "ch() { cheat $* }", ".config/zsh/plugins/cheat.zsh"
        )
        shortcuts = first + second
        ch_records = [shortcut for shortcut in shortcuts if shortcut.name == "ch"]
        self.assertEqual(len(ch_records), 2)
        self.assertEqual(
            {shortcut.source for shortcut in ch_records},
            {".config/zsh/plugins/bat.zsh", ".config/zsh/plugins/cheat.zsh"},
        )


if __name__ == "__main__":
    unittest.main()
