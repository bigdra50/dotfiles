""".claude/hooks/ja-reply-stop.py（Stop hook）が、日本語でない返答を書き直させる範囲の仕様。

Usage:
    python3 -m unittest discover -s scripts/tests
"""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / ".claude" / "hooks" / "ja-reply-stop.py"

JAPANESE = (
    "`main` を push しました。\n"
    "CI は build と lint のどちらも成功し、preview の prerelease も置き換わりました。\n"
    "```bash\ngit push origin main\n```\n"
)
ENGLISH = (
    "I pushed main and rebased the branch onto it.\n"
    "CI passed on both branches, and the previews were replaced with the latest PDFs.\n"
)


def user_prompt(text: str) -> dict:
    return {"type": "user", "message": {"role": "user", "content": text}}


def tool_result() -> dict:
    return {
        "type": "user",
        "message": {
            "role": "user",
            "content": [{"type": "tool_result", "tool_use_id": "t1", "content": "ok"}],
        },
    }


def assistant(*texts: str) -> dict:
    return {
        "type": "assistant",
        "message": {
            "role": "assistant",
            "content": [{"type": "text", "text": t} for t in texts],
        },
    }


class JaReplyStopTest(unittest.TestCase):
    def setUp(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.transcript = Path(tmp.name) / "session.jsonl"

    def run_hook(self, entries: list[dict], **payload: object) -> tuple[int, str]:
        self.transcript.write_text(
            "\n".join(json.dumps(e, ensure_ascii=False) for e in entries) + "\n",
            encoding="utf-8",
        )
        body = {
            "hook_event_name": "Stop",
            "transcript_path": str(self.transcript),
            "stop_hook_active": False,
        } | payload
        actual = subprocess.run(
            ["python3", str(HOOK)],
            input=json.dumps(body),
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        return actual.returncode, actual.stdout

    def test_japanese_reply_passes(self) -> None:
        code, out = self.run_hook([user_prompt("push して"), assistant(JAPANESE)])
        self.assertEqual((code, out), (0, ""))

    def test_english_reply_is_blocked_with_reason(self) -> None:
        code, out = self.run_hook([user_prompt("push して"), assistant(ENGLISH)])
        self.assertEqual(code, 0)
        actual = json.loads(out)
        self.assertEqual(actual["decision"], "block")
        self.assertIn("日本語", actual["reason"])

    def test_english_progress_note_before_a_japanese_summary_is_blocked(self) -> None:
        entries = [
            user_prompt("push して"),
            assistant(ENGLISH),
            tool_result(),
            # ターン全体で数えると日本語が多数になる長さにする
            assistant(JAPANESE * 4),
        ]
        _, out = self.run_hook(entries)
        self.assertEqual(json.loads(out)["decision"], "block")

    def test_only_the_latest_turn_is_judged(self) -> None:
        entries = [
            user_prompt("一つ目"),
            assistant(ENGLISH),
            user_prompt("二つ目"),
            assistant(JAPANESE),
        ]
        self.assertEqual(self.run_hook(entries), (0, ""))

    def test_short_english_reply_passes(self) -> None:
        self.assertEqual(
            self.run_hook([user_prompt("ok?"), assistant("Done.")]), (0, "")
        )

    def test_code_urls_and_inline_code_are_not_counted_as_english(self) -> None:
        reply = (
            "結果です。\n"
            "```\nTraceback (most recent call last): ValueError: resume requires an explicit root directory\n```\n"
            "`git push --force-with-lease origin drop-appendix-b` と https://github.com/bigdra50/tech-books/releases\n"
        )
        self.assertEqual(
            self.run_hook([user_prompt("どう?"), assistant(reply)]), (0, "")
        )

    def test_second_stop_after_a_rewrite_request_passes(self) -> None:
        self.assertEqual(
            self.run_hook(
                [user_prompt("push して"), assistant(ENGLISH)], stop_hook_active=True
            ),
            (0, ""),
        )

    def test_broken_input_passes_silently(self) -> None:
        actual = subprocess.run(
            ["python3", str(HOOK)],
            input="not json",
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        self.assertEqual((actual.returncode, actual.stdout), (0, ""))

    def test_missing_transcript_passes_silently(self) -> None:
        body = {
            "hook_event_name": "Stop",
            "transcript_path": "/nonexistent/x.jsonl",
            "stop_hook_active": False,
        }
        actual = subprocess.run(
            ["python3", str(HOOK)],
            input=json.dumps(body),
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
        self.assertEqual((actual.returncode, actual.stdout), (0, ""))


if __name__ == "__main__":
    unittest.main()
