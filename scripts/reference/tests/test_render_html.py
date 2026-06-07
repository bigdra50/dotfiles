"""Tests for the generic searchable HTML renderer."""

from __future__ import annotations

import json
import re
import unittest

from common.render_html import render_searchable_html
from keybindings.page import PAGE_CONFIG


def _sample_record(**overrides: str) -> dict[str, str]:
    base: dict[str, str] = {
        "tool": "nvim",
        "context": "global:all-loaded",
        "mode": "n",
        "key": "q",
        "action": ":q<CR>",
        "description": "quit",
        "source": ".config/nvim",
        "origin": "custom",
        "change": "added",
    }
    base.update(overrides)
    return base


def _meta(**overrides: str) -> dict[str, str]:
    base = {
        "generated_at": "2026-01-01T00:00:00+00:00",
        "commit": "abc1234",
        "counts": json.dumps({"nvim": 1}),
    }
    base.update(overrides)
    return base


class TestRenderHtml(unittest.TestCase):
    def test_data_embedded_in_output(self) -> None:
        output = render_searchable_html([_sample_record()], PAGE_CONFIG, _meta())
        self.assertIn("const DATA", output)
        self.assertIn("const CONFIG", output)

    def test_script_injection_neutralized(self) -> None:
        records = [_sample_record(action="</script><b>x")]
        output = render_searchable_html(records, PAGE_CONFIG, _meta())
        data_match = re.search(r"const DATA = (\[.*?\]);", output, re.DOTALL)
        self.assertIsNotNone(data_match)
        data_json = data_match.group(1) if data_match else ""
        self.assertIn(r"<\/script>", data_json)
        self.assertNotIn("</script><b>x", data_json)

    def test_leader_not_emitted_as_html_tag(self) -> None:
        records = [_sample_record(key="<leader>ff", action="Telescope find_files")]
        output = render_searchable_html(records, PAGE_CONFIG, _meta())
        before_script, after_data = output.split("const DATA = ", 1)
        _script_body, after_script = after_data.split("</script>", 1)
        self.assertNotIn("<leader>", before_script)
        self.assertNotIn("<leader>", after_script)
        self.assertNotRegex(before_script, r"<leader[^>]*>")

    def test_meta_counts_appear(self) -> None:
        records = [_sample_record(tool="zsh"), _sample_record(tool="skhd")]
        meta = _meta(commit="deadbeef", counts=json.dumps({"zsh": 12, "skhd": 34}))
        output = render_searchable_html(records, PAGE_CONFIG, meta)
        self.assertIn("12", output)
        self.assertIn("34", output)
        self.assertIn("zsh", output)
        self.assertIn("skhd", output)

    def test_column_labels_embedded(self) -> None:
        output = render_searchable_html([_sample_record()], PAGE_CONFIG, _meta())
        config_match = re.search(r"const CONFIG = (\{.*?\});", output, re.DOTALL)
        self.assertIsNotNone(config_match)
        config_json = config_match.group(1) if config_match else ""
        config = json.loads(config_json.replace(r"<\/", "</"))
        labels = [c["label"] for c in config["columns"]]
        self.assertEqual(
            labels,
            ["Tool", "Mode", "Key", "Action", "Description", "Source", "Change"],
        )


if __name__ == "__main__":
    unittest.main()
