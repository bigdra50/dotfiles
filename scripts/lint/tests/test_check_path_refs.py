"""Tests for scripts/ path reference checking."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

import check_path_refs as checker


def _write(root: Path, rel_path: str, content: str) -> None:
    target = root / rel_path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(content, encoding="utf-8")


class TestCheckPathRefs(unittest.TestCase):
    def test_existing_file_reference_has_no_violation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "scripts/build.sh", "#!/usr/bin/env bash\n")
            _write(root, ".github/workflows/test.yml", "run: bash scripts/build.sh\n")

            violations, tokens_checked = checker.check_path_refs(root)

            self.assertEqual(violations, [])
            self.assertEqual(tokens_checked, 1)

    def test_missing_file_reference_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, ".github/workflows/test.yml", "run: bash scripts/missing.sh\n")

            violations, _ = checker.check_path_refs(root)

            self.assertEqual(
                violations, [".github/workflows/test.yml:1: scripts/missing.sh"]
            )

    def test_glob_with_zero_matches_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "scripts" / "setup").mkdir(parents=True)
            _write(
                root,
                ".github/workflows/test.yml",
                "run: shellcheck scripts/setup/*.sh\n",
            )

            violations, _ = checker.check_path_refs(root)

            self.assertEqual(
                violations, [".github/workflows/test.yml:1: scripts/setup/*.sh"]
            )

    def test_glob_with_matches_is_ok(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "scripts/setup/base.sh", "")
            _write(
                root,
                ".github/workflows/test.yml",
                "run: shellcheck scripts/setup/*.sh\n",
            )

            violations, _ = checker.check_path_refs(root)

            self.assertEqual(violations, [])

    def test_recursive_glob_pattern_matches(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "scripts/reference/extract.py", "")
            _write(
                root, ".github/workflows/test.yml", '      - "scripts/reference/**"\n'
            )

            violations, _ = checker.check_path_refs(root)

            self.assertEqual(violations, [])

    def test_comment_line_is_ignored(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                ".github/workflows/test.yml",
                "  # run: bash scripts/missing.sh\n",
            )

            violations, tokens_checked = checker.check_path_refs(root)

            self.assertEqual(violations, [])
            self.assertEqual(tokens_checked, 0)

    def test_url_embedded_path_is_not_extracted(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(
                root,
                ".github/workflows/test.yml",
                "run: curl https://example.com/x/main/scripts/download.bash\n",
            )

            violations, tokens_checked = checker.check_path_refs(root)

            self.assertEqual(violations, [])
            self.assertEqual(tokens_checked, 0)

    def test_directory_reference_is_ok(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, "scripts/reference/.keep", "")
            _write(
                root,
                ".github/workflows/test.yml",
                "run: ruff check scripts/reference/\n",
            )

            violations, _ = checker.check_path_refs(root)

            self.assertEqual(violations, [])

    def test_allowlisted_violation_is_excluded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _write(root, ".github/workflows/test.yml", "run: bash scripts/missing.sh\n")

            with mock.patch.object(
                checker, "ALLOWLIST", frozenset({".github/workflows/test.yml:1"})
            ):
                violations, _ = checker.check_path_refs(root)

            self.assertEqual(violations, [])


class TestCheckPathRefsIntegration(unittest.TestCase):
    def test_repo_has_zero_violations(self) -> None:
        repo_root = Path(__file__).resolve().parents[3]

        violations, _ = checker.check_path_refs(repo_root)

        self.assertEqual(violations, [])


if __name__ == "__main__":
    unittest.main()
