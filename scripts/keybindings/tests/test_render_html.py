"""Tests for searchable HTML rendering."""

from __future__ import annotations

import json
import re
import unittest

from keybindings.render_html import render_searchable_html


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


class TestRenderHtml(unittest.TestCase):
    def test_data_embedded_in_output(self) -> None:
        records = [_sample_record()]
        meta = {
            "generated_at": "2026-01-01T00:00:00+00:00",
            "commit": "abc1234",
            "counts": json.dumps({"nvim": 1}),
            "note": "nvim: global maps only (v1)",
        }
        output = render_searchable_html(records, meta)
        self.assertIn("const DATA", output)

    def test_script_injection_neutralized(self) -> None:
        records = [_sample_record(action="</script><b>x")]
        meta = {
            "generated_at": "2026-01-01T00:00:00+00:00",
            "commit": "abc1234",
            "counts": json.dumps({"nvim": 1}),
            "note": "nvim: global maps only (v1)",
        }
        output = render_searchable_html(records, meta)
        data_match = re.search(r"const DATA = (\[.*?\]);", output, re.DOTALL)
        self.assertIsNotNone(data_match)
        data_json = data_match.group(1) if data_match else ""
        self.assertIn(r"<\/script>", data_json)
        self.assertNotIn("</script><b>x", data_json)

    def test_leader_not_emitted_as_html_tag(self) -> None:
        records = [_sample_record(key="<leader>ff", action="Telescope find_files")]
        meta = {
            "generated_at": "2026-01-01T00:00:00+00:00",
            "commit": "abc1234",
            "counts": json.dumps({"nvim": 1}),
            "note": "nvim: global maps only (v1)",
        }
        output = render_searchable_html(records, meta)
        before_script, after_data = output.split("const DATA = ", 1)
        script_body, after_script = after_data.split("</script>", 1)
        self.assertIn("<leader>ff", script_body)
        self.assertNotIn("<leader>", before_script)
        self.assertNotIn("<leader>", after_script)
        self.assertNotRegex(before_script, r"<leader[^>]*>")

    def test_meta_counts_appear(self) -> None:
        records = [_sample_record(tool="zsh"), _sample_record(tool="skhd")]
        meta = {
            "generated_at": "2026-06-07T12:00:00+00:00",
            "commit": "deadbeef",
            "counts": json.dumps({"zsh": 12, "skhd": 34}),
            "note": "nvim: global maps only (v1)",
        }
        output = render_searchable_html(records, meta)
        self.assertIn("12", output)
        self.assertIn("34", output)
        self.assertIn("zsh", output)
        self.assertIn("skhd", output)


if __name__ == "__main__":
    unittest.main()
