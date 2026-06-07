"""Tests for the hub renderer and shared navigation."""

from __future__ import annotations

import unittest

from common.hub_html import render_hub
from common.nav import build_nav


class TestNav(unittest.TestCase):
    def test_domain_page_uses_parent_relative_hrefs(self) -> None:
        links = build_nav("keybindings")
        hrefs = [link.href for link in links]
        self.assertEqual(
            hrefs,
            ["../", "../keybindings/", "../shortcuts/", "../tasks/", "../claude/"],
        )

    def test_active_flag_matches_slug(self) -> None:
        links = build_nav("shortcuts")
        active = [link.label for link in links if link.active]
        self.assertEqual(active, ["Shortcuts"])

    def test_hub_base_marks_overview_active(self) -> None:
        links = build_nav("home", base="./")
        overview = next(link for link in links if link.label == "Overview")
        self.assertTrue(overview.active)
        self.assertEqual(overview.href, "./")


class TestRenderHub(unittest.TestCase):
    def _cards(self) -> list[dict[str, str]]:
        return [
            {
                "slug": "keybindings",
                "label": "Keybindings",
                "count": "384",
                "note": "n",
            },
            {"slug": "shortcuts", "label": "Shortcuts", "count": "80", "note": "n"},
        ]

    def test_counts_and_links_present(self) -> None:
        meta = {"generated_at": "2026-01-01T00:00:00+00:00", "commit": "abc1234"}
        output = render_hub(self._cards(), meta)
        self.assertIn("384", output)
        self.assertIn("href='keybindings/'", output)
        self.assertIn("Dotfiles Reference", output)

    def test_card_label_escaped(self) -> None:
        meta = {"generated_at": "", "commit": ""}
        cards = [{"slug": "x", "label": "<b>x", "count": "1", "note": ""}]
        output = render_hub(cards, meta)
        self.assertNotIn("<b>x", output)
        self.assertIn("&lt;b&gt;x", output)


if __name__ == "__main__":
    unittest.main()
