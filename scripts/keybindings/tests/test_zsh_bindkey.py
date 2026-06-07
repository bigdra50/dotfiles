"""Tests for Zsh bindkey parsing."""

from __future__ import annotations

import unittest
from pathlib import Path

from keybindings.schema import Keybinding
from keybindings.zsh_bindkey import (
    collapse_equivalent_sequences,
    humanize_key_sequence,
    parse_bindkey_line,
    parse_bindkey_text,
)

FIXTURES = Path(__file__).parent / "fixtures"


class TestZshBindkey(unittest.TestCase):
    def setUp(self) -> None:
        self.fixture_text = (FIXTURES / "zsh-bindkeys.zsh").read_text(encoding="utf-8")

    def test_parse_bindkey_line_ignores_vi_keymap_switch(self) -> None:
        self.assertIsNone(parse_bindkey_line("bindkey -v"))

    def test_parse_bindkey_line_parses_quoted_sequences(self) -> None:
        parsed = parse_bindkey_line('bindkey "^ " magic-space')
        assert parsed is not None
        self.assertEqual(parsed.sequence, "^ ")
        self.assertEqual(parsed.widget, "magic-space")

    def test_parse_bindkey_line_raises_on_unsupported_option(self) -> None:
        with self.assertRaises(ValueError):
            parse_bindkey_line("bindkey -M viins '^A' beginning-of-line")

    def test_parse_bindkey_line_raises_on_invalid_syntax(self) -> None:
        with self.assertRaises(ValueError):
            parse_bindkey_line("bindkey broken")

    def test_humanize_key_sequence(self) -> None:
        self.assertEqual(humanize_key_sequence("^M"), "Ctrl+M")
        self.assertEqual(humanize_key_sequence("^ "), "Ctrl+Space")
        self.assertEqual(humanize_key_sequence("^Xs"), "Ctrl+X s")
        self.assertEqual(humanize_key_sequence(r"\e[A"), "Up")
        self.assertEqual(humanize_key_sequence("jj"), "jj")
        self.assertEqual(humanize_key_sequence(" "), "Space")

    def test_parse_bindkey_text_fixture_count(self) -> None:
        bindings = parse_bindkey_text(self.fixture_text, ".config/zsh/fixture.zsh")
        self.assertEqual(len(bindings), 13)

    def test_collapse_equivalent_sequences_merges_up_down(self) -> None:
        first = Keybinding(
            tool="zsh",
            context="zle",
            mode="viins",
            key="Up",
            action="history-beginning-search-backward",
            description="",
            source=".config/zsh/first.zsh",
            origin="custom",
            change="added",
        )
        second = Keybinding(
            tool="zsh",
            context="zle",
            mode="viins",
            key="Up",
            action="history-beginning-search-backward",
            description="",
            source=".config/zsh/second.zsh",
            origin="custom",
            change="added",
        )
        collapsed = collapse_equivalent_sequences([first, second])
        self.assertEqual(len(collapsed), 1)
        self.assertEqual(collapsed[0].source, ".config/zsh/first.zsh")

    def test_collapse_equivalent_sequences_keeps_different_actions(self) -> None:
        first = Keybinding(
            tool="zsh",
            context="zle",
            mode="viins",
            key="Up",
            action="history-beginning-search-backward",
            description="",
            source=".config/zsh/first.zsh",
            origin="custom",
            change="added",
        )
        second = Keybinding(
            tool="zsh",
            context="zle",
            mode="viins",
            key="Up",
            action="up-line-or-history",
            description="",
            source=".config/zsh/second.zsh",
            origin="custom",
            change="added",
        )
        collapsed = collapse_equivalent_sequences([first, second])
        self.assertEqual(len(collapsed), 2)


if __name__ == "__main__":
    unittest.main()
