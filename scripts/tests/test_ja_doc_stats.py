"""scripts/ja-doc-stats.py の仕様。

Usage:
    python3 -m unittest discover -s scripts/tests
"""

from __future__ import annotations

import contextlib
import importlib.util
import io
import sys
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path
from types import ModuleType

REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module() -> ModuleType:
    """ハイフン入りのファイル名は import できないのでパスから読む。"""
    path = REPO_ROOT / "scripts" / "ja-doc-stats.py"
    spec = importlib.util.spec_from_file_location("ja_doc_stats", path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules["ja_doc_stats"] = module
    spec.loader.exec_module(module)
    return module


jds = load_module()


def sentences(text: str) -> list[str]:
    return [s.text for s in jds.split_sentences(text.splitlines())]


def run(text: str, **overrides: object) -> list[str]:
    args = Namespace(
        max_ending_run=jds.DEFAULT_MAX_ENDING_RUN,
        mix_ratio=jds.DEFAULT_MIX_RATIO,
        min_sentences=jds.DEFAULT_MIN_SENTENCES,
        metaphor_max=jds.DEFAULT_METAPHOR_MAX,
    )
    checks = overrides.pop("checks", jds.CHECK_IDS)
    for key, value in overrides.items():
        setattr(args, key, value)
    return [v.check for v in jds.inspect(text.splitlines(), checks, args)]


class ExtractionTest(unittest.TestCase):
    def test_non_prose_blocks_are_excluded(self) -> None:
        text = (
            "---\ntitle: フロントマターは対象外。\n---\n"
            "# 見出しは対象外。\n"
            "- 箇条書きは対象外。\n"
            "1. 順序付きも対象外。\n"
            "| 表 | も対象外。 |\n"
            "> 引用も対象外。\n"
            "```\nコードも対象外。\n```\n"
            "地の文だけを数える。\n"
        )
        self.assertEqual(sentences(text), ["地の文だけを数える。"])

    def test_inline_code_is_removed(self) -> None:
        # コード断片の句点で文が切れると、地の文の文末を取り違える。
        self.assertEqual(len(sentences('設定は `["。"]` と書く。\n')), 1)

    def test_fragment_without_period_is_not_a_sentence(self) -> None:
        self.assertEqual(sentences("次の設定を書く:\n"), [])

    def test_english_prose_is_ignored(self) -> None:
        self.assertEqual(sentences("This is a sentence.\n"), [])

    def test_period_inside_a_quote_does_not_split(self) -> None:
        # 引用の途中の句点で切ると、引用元の文体の文が 1 つ生まれる。
        text = "「隣は本部ビルです。来店はご遠慮ください」と告知した。\n"
        self.assertEqual(sentences(text), [text.strip()])

    def test_unclosed_quote_does_not_swallow_the_paragraph(self) -> None:
        # 開き括弧の書き落としの影響は段落内に留める。
        text = "「閉じ忘れた。\n\n次の段落は数える。\n"
        self.assertIn("次の段落は数える。", sentences(text))

    def test_quotation_only_line_is_not_counted(self) -> None:
        # 行全体が引用なら文末は引用元のもので、書き手の文体ではない。
        self.assertEqual(sentences("「必ずご確認ください」。\n"), [])

    def test_quotation_with_prose_is_counted(self) -> None:
        # 地の文を伴うなら文末は書き手のもの。
        self.assertEqual(
            sentences("「必ず確認を」と述べた。\n"), ["「必ず確認を」と述べた。"]
        )


class ClassifyTest(unittest.TestCase):
    def test_polite_forms(self) -> None:
        for body in ("動きます。", "動きました。", "動きません。", "動くでしょうか。"):
            self.assertEqual(jds.classify(body)[1], jds.POLITE, body)

    def test_plain_forms(self) -> None:
        for body in ("動く。", "動いた。", "速い。", "動かない。", "仕様である。"):
            self.assertEqual(jds.classify(body)[1], jds.PLAIN, body)

    def test_noun_ending_is_neither(self) -> None:
        for body in ("実行は不要。", "詳細は付録を参照。", "残りは 2 つ。"):
            self.assertEqual(jds.classify(body)[1], jds.OTHER, body)

    def test_tense_variants_are_distinct_endings(self) -> None:
        keys = {
            jds.classify(b)[0] for b in ("動きます。", "動きました。", "動きません。")
        }
        self.assertEqual(len(keys), 3)


class EndingRunTest(unittest.TestCase):
    def test_three_in_one_paragraph(self) -> None:
        text = "対応します。\n改善します。\n公開します。\n"
        self.assertEqual(run(text), ["ending-run"])

    def test_paragraph_break_needs_one_more(self) -> None:
        text = "対応します。\n改善します。\n\n公開します。\n"
        self.assertEqual(run(text), [])
        self.assertEqual(run(text + "追加します。\n"), ["ending-run"])

    def test_tense_variation_is_not_a_run(self) -> None:
        self.assertEqual(run("対応します。\n改善しました。\n公開しません。\n"), [])

    def test_heading_between_sentences_resets_the_run(self) -> None:
        text = "対応します。\n改善します。\n\n## 節\n\n公開します。\n追加します。\n"
        self.assertEqual(run(text), [])


class StyleMixTest(unittest.TestCase):
    def build(self, polite: int, plain: int) -> str:
        lines = ["対応します。"] * polite + ["対応する。"] * plain
        # 文末の連続で落ちないよう、この検査だけを見る
        return "\n\n".join(lines) + "\n"

    def test_minority_is_reported(self) -> None:
        text = self.build(polite=2, plain=25)
        self.assertEqual(run(text, checks=("style-mix",)), ["style-mix", "style-mix"])

    def test_balanced_document_is_not_reported(self) -> None:
        self.assertEqual(
            run(self.build(polite=12, plain=15), checks=("style-mix",)), []
        )

    def test_short_document_is_not_reported(self) -> None:
        self.assertEqual(run(self.build(polite=1, plain=10), checks=("style-mix",)), [])

    def test_reported_lines_are_capped(self) -> None:
        found = run(self.build(polite=8, plain=200), checks=("style-mix",))
        self.assertEqual(len(found), jds.MAX_REPORTED_MIX)


class MetaphorTest(unittest.TestCase):
    def test_stacked_metaphors(self) -> None:
        text = "まるで生き物のように振る舞う。\n"
        self.assertEqual(run(text, checks=("metaphor",)), ["metaphor"])

    def test_deictic_reference_is_not_a_metaphor(self) -> None:
        text = "以下のように書く。\n次のような形にする。\n"
        self.assertEqual(run(text, checks=("metaphor",)), [])


class CliTest(unittest.TestCase):
    def test_exit_codes(self) -> None:
        with tempfile.TemporaryDirectory() as workdir:
            target = Path(workdir) / "doc.md"
            target.write_text(
                "設定を読み込む。\n失敗したら中断します。\n", encoding="utf-8"
            )
            self.assertEqual(jds.main([str(target)]), 0)
            target.write_text(
                "対応します。\n改善します。\n公開します。\n", encoding="utf-8"
            )
            # ending-run は warning。指摘は出るが終了コードは 0 のままで、
            # 誤検知が CI と Stop フックを止めないようにしてある。
            with contextlib.redirect_stdout(io.StringIO()) as out:
                self.assertEqual(jds.main([str(target)]), 0)
            self.assertIn("ending-run", out.getvalue())
            self.assertIn("warning", out.getvalue())

    def test_error_severity_sets_exit_code(self) -> None:
        """style-mix は error なので終了コードを 1 にする。"""
        with tempfile.TemporaryDirectory() as workdir:
            target = Path(workdir) / "doc.md"
            body = "".join(f"項目{i}を確認する。\n" for i in range(25))
            target.write_text(body + "最後に報告します。\n", encoding="utf-8")
            with contextlib.redirect_stdout(io.StringIO()) as out:
                self.assertEqual(jds.main([str(target)]), 1)
            self.assertIn("style-mix", out.getvalue())
            self.assertIn("error", out.getvalue())

    def test_missing_file_is_skipped(self) -> None:
        self.assertEqual(jds.main(["/nonexistent/path.md"]), 0)


if __name__ == "__main__":
    unittest.main()
