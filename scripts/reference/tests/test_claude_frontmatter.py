"""Tests for Claude frontmatter parsing."""

from __future__ import annotations

import unittest

from claude.frontmatter import parse_frontmatter


class TestClaudeFrontmatter(unittest.TestCase):
    def test_parse_simple_key_value_pairs(self) -> None:
        text = "---\nname: example\ndescription: Simple description\nmodel: sonnet\n---\n\n# Body\n"
        parsed = parse_frontmatter(text)
        assert parsed is not None
        self.assertEqual(parsed["name"], "example")
        self.assertEqual(parsed["description"], "Simple description")
        self.assertEqual(parsed["model"], "sonnet")

    def test_parse_block_scalar_description_collapses_to_single_line(self) -> None:
        text = (
            "---\n"
            "description: |\n"
            "  First line of description.\n"
            "  Second line of description.\n"
            "name: block-skill\n"
            "---\n"
        )
        parsed = parse_frontmatter(text)
        assert parsed is not None
        self.assertEqual(
            parsed["description"],
            "First line of description. Second line of description.",
        )
        self.assertEqual(parsed["name"], "block-skill")

    def test_missing_frontmatter_returns_none(self) -> None:
        self.assertIsNone(parse_frontmatter("# No frontmatter here\n"))
        self.assertIsNone(parse_frontmatter("---\nname: missing-close\n"))

    def test_unknown_keys_are_kept_without_crashing(self) -> None:
        text = (
            "---\n"
            "name: known\n"
            "description: Known description\n"
            "allowed-tools:\n"
            "  - Read\n"
            "  - Grep\n"
            "custom-flag: yes\n"
            "---\n"
        )
        parsed = parse_frontmatter(text)
        assert parsed is not None
        self.assertEqual(parsed["name"], "known")
        self.assertEqual(parsed["description"], "Known description")
        self.assertEqual(parsed["custom-flag"], "yes")


if __name__ == "__main__":
    unittest.main()
