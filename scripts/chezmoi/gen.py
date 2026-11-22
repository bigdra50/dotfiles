#!/usr/bin/env python3
"""home/.chezmoidata/dotfiles.toml から chezmoi のソースを生成する。

Usage:
    python3 scripts/chezmoi/gen.py           生成物を書き出し、古い生成物を消す
    python3 scripts/chezmoi/gen.py --check   定義の違反と、生成物とのずれを報告する（書き込まない）
"""

from __future__ import annotations

import io
import sys
from pathlib import Path

from manifest import check_manifest, load_manifest
from render import is_generated, render

REPO_ROOT = Path(__file__).resolve().parents[2]
HOME_DIR = REPO_ROOT / "home"
MANIFEST_PATH = HOME_DIR / ".chezmoidata" / "dotfiles.toml"


def existing_generated(home: Path) -> set[str]:
    return {
        path.relative_to(home).as_posix()
        for path in home.rglob("*")
        if path.is_file() and is_generated(path.relative_to(home).as_posix())
    }


def drift(home: Path, expected: dict[str, str]) -> list[str]:
    """生成物と home/ の内容のずれを列挙する。"""
    problems: list[str] = []
    for name, content in sorted(expected.items()):
        path = home / name
        if not path.is_file():
            problems.append(f"生成されていない: {name}")
        elif path.read_text(encoding="utf-8") != content:
            problems.append(f"定義と違う: {name}")
    problems.extend(
        f"定義に無い生成物: {name}"
        for name in sorted(existing_generated(home) - set(expected))
    )
    return problems


def write(home: Path, expected: dict[str, str]) -> list[str]:
    """生成物を書き出し、変えたパスを返す。"""
    changed: list[str] = []
    for name in sorted(existing_generated(home) - set(expected)):
        (home / name).unlink()
        changed.append(f"削除 {name}")
    for name, content in sorted(expected.items()):
        path = home / name
        if path.is_file() and path.read_text(encoding="utf-8") == content:
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        # Windows でも LF で書く。chezmoi はリンク定義の中身をそのまま symlink の指し先にする
        path.write_text(content, encoding="utf-8", newline="\n")
        changed.append(f"生成 {name}")
    # 生成物を消して空になったディレクトリは、chezmoi が空のディレクトリとして配置してしまう
    for directory in sorted((p for p in home.rglob("*") if p.is_dir()), reverse=True):
        if not any(directory.iterdir()):
            directory.rmdir()
    return changed


def main(argv: list[str]) -> int:
    # Windows の既定の文字コードでは、日本語のメッセージを出力できずに例外になる
    for stream in (sys.stdout, sys.stderr):
        if isinstance(stream, io.TextIOWrapper):
            stream.reconfigure(encoding="utf-8")
    check_only = argv == ["--check"]
    if argv and not check_only:
        print(__doc__, file=sys.stderr)
        return 2

    manifest = load_manifest(MANIFEST_PATH)
    violations = check_manifest(manifest, lambda path: (REPO_ROOT / path).exists())
    if violations:
        print("\n".join(violations), file=sys.stderr)
        return 1

    expected = render(manifest)
    if check_only:
        problems = drift(HOME_DIR, expected)
        if problems:
            print("\n".join(problems), file=sys.stderr)
            print("mise run chezmoi:gen で作り直す", file=sys.stderr)
            return 1
        return 0

    for line in write(HOME_DIR, expected):
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
