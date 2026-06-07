"""Tests for duplicate key detection."""

from __future__ import annotations

import unittest

from keybindings.dedup import detect_duplicate_keys


class TestDedup(unittest.TestCase):
    def test_detect_duplicate_keys_finds_duplicates(self) -> None:
        records = [
            {
                "tool": "zsh",
                "context": "zle",
                "mode": "viins",
                "key": "jj",
                "action": "vi-cmd-mode",
                "description": "",
                "source": ".config/zsh/interface.zsh",
                "origin": "custom",
                "change": "added",
            },
            {
                "tool": "zsh",
                "context": "zle",
                "mode": "viins",
                "key": "jj",
                "action": "other-widget",
                "description": "",
                "source": ".config/zsh/other.zsh",
                "origin": "custom",
                "change": "added",
            },
        ]
        duplicates = detect_duplicate_keys(records)
        self.assertEqual(duplicates, [("zsh", "zle", "viins", "jj")])

    def test_detect_duplicate_keys_returns_empty_when_unique(self) -> None:
        records = [
            {
                "tool": "skhd",
                "context": "focus window",
                "mode": "alt",
                "key": "x",
                "action": "cmd-a",
                "description": "",
                "source": ".skhdrc",
                "origin": "custom",
                "change": "added",
            },
            {
                "tool": "skhd",
                "context": "focus window",
                "mode": "alt",
                "key": "h",
                "action": "cmd-b",
                "description": "",
                "source": ".skhdrc",
                "origin": "custom",
                "change": "added",
            },
        ]
        self.assertEqual(detect_duplicate_keys(records), [])


if __name__ == "__main__":
    unittest.main()
