#!/usr/bin/env python3
"""Verify scripts/ path references in CI and task definitions resolve to real files."""

from __future__ import annotations

import glob
import re
import sys
from pathlib import Path

# Path prefixes this checker validates. A tuple so future prefixes (e.g. ".claude/")
# can be added without touching the extraction logic.
PREFIXES: tuple[str, ...] = ("scripts/",)

# Files that define executable references: CI workflows, mise tasks, and the
# shell entry points that invoke scripts/ directly.
SOURCE_GLOBS: tuple[str, ...] = (
    ".github/workflows/*.yml",
    "mise.toml",
    ".config/mise/config.toml",
    "scripts/**/*.sh",
    "install.sh",
    "bootstrap",
)

# Intentional exceptions, keyed by "file:line" (relative to repo root).
ALLOWLIST: frozenset[str] = frozenset()

GLOB_CHARS = ("*", "?", "[")


def _build_token_pattern(prefixes: tuple[str, ...]) -> re.Pattern[str]:
    alternation = "|".join(re.escape(prefix) for prefix in prefixes)
    # Negative lookbehind excludes matches embedded in a longer path or URL,
    # e.g. ".../main/scripts/download-actionlint.bash" or ".claude/skills/x/scripts/".
    return re.compile(rf"(?<![A-Za-z0-9_./-])(?:{alternation})[A-Za-z0-9_./*?\[\]-]*")


TOKEN_PATTERN = _build_token_pattern(PREFIXES)


def collect_source_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for pattern in SOURCE_GLOBS:
        files.extend(sorted(match for match in root.glob(pattern) if match.is_file()))
    return files


def extract_tokens(path: Path) -> list[tuple[int, str]]:
    tokens: list[tuple[int, str]] = []
    text = path.read_text(encoding="utf-8")
    for line_number, line in enumerate(text.splitlines(), start=1):
        if line.lstrip().startswith("#"):
            continue
        for match in TOKEN_PATTERN.finditer(line):
            token = match.group(0).rstrip(".")
            tokens.append((line_number, token))
    return tokens


def is_glob_token(token: str) -> bool:
    return any(char in token for char in GLOB_CHARS)


def token_resolves(token: str, root: Path) -> bool:
    if is_glob_token(token):
        return len(glob.glob(token, root_dir=root, recursive=True)) > 0
    target = root / token
    return target.is_file() or target.is_dir()


def check_path_refs(root: Path) -> tuple[list[str], int]:
    """Return (violations, tokens_checked) for scripts/ path references under root."""
    violations: list[str] = []
    tokens_checked = 0

    for source_file in collect_source_files(root):
        rel_source = source_file.relative_to(root).as_posix()
        for line_number, token in extract_tokens(source_file):
            tokens_checked += 1
            key = f"{rel_source}:{line_number}"
            if key in ALLOWLIST:
                continue
            if not token_resolves(token, root):
                violations.append(f"{key}: {token}")

    return violations, tokens_checked


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    violations, tokens_checked = check_path_refs(root)

    if violations:
        for violation in violations:
            print(violation, file=sys.stderr)
        return 1

    print(f"OK: {tokens_checked} scripts/ path reference(s) checked, 0 violations")
    return 0


if __name__ == "__main__":
    sys.exit(main())
