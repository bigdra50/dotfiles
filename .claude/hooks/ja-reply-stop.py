#!/usr/bin/env python3
"""Stop hook: このターンの返答が日本語で書かれていなければ、日本語で書き直させる。

判定は、このターン (最後のユーザープロンプト以降) に Claude が書いた text のブロックごとに、
かなの数と英単語の数の比で行う。途中の経過報告が英語なら、最後のまとめが日本語でも書き直させる。
コードブロック、インラインコード、URL は数えない。
識別子やコマンドの多い日本語の返答でも、かなの割合は 0.87 以上だった。
英語の返答は、引用した日本語を含めても 0.21 以下だった (2026-10-24 の実測)。

無限ループは stop_hook_active で避ける。書き直しの要求は 1 ターンにつき 1 回で止まる。

安全弁:
  1. 入力が壊れている・transcript が読めない・例外 → 何も出さず exit 0 (フェイルオープン)
  2. 英単語が MIN_WORDS 語に満たない短い返答は判定しない
  3. CLAUDE_JA_REPLY_DISABLE=1 で無効化
"""

from __future__ import annotations

import contextlib
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

# 実測で日本語の返答は 0.87 以上、英語の返答は 0.21 以下。その間で余裕を取る
MIN_KANA_RATIO = 0.5
# 「Done.」のような短い返答は言語を問わず通す
MIN_WORDS = 8

CODE_BLOCK = re.compile(r"```.*?```", re.DOTALL)
INLINE_CODE = re.compile(r"`[^`\n]*`")
URL = re.compile(r"https?://\S+")
KANA = re.compile(r"[぀-ヿ]")
WORD = re.compile(r"[A-Za-z]{2,}")

REASON = (
    "このターンの返答に、日本語で書かれていない段落がある（かな {kana} 字、英単語 {words} 語）。"
    "その内容を日本語で書き直して、返答し直す。新しい作業はしない。"
)


def prose(text: str) -> str:
    """本文だけを残す。コードと URL は言語の判定に使わない。"""
    return URL.sub(" ", INLINE_CODE.sub(" ", CODE_BLOCK.sub(" ", text)))


def counts(text: str) -> tuple[int, int]:
    body = prose(text)
    return len(KANA.findall(body)), len(WORD.findall(body))


def needs_rewrite(text: str) -> tuple[bool, int, int]:
    kana, words = counts(text)
    if words < MIN_WORDS:
        return False, kana, words
    return kana / (kana + words) < MIN_KANA_RATIO, kana, words


def is_user_prompt(entry: dict[str, Any]) -> bool:
    """tool_result ではない、ユーザーが送った発言か。"""
    message = entry.get("message")
    if entry.get("type") != "user" or not isinstance(message, dict):
        return False
    content = message.get("content")
    if isinstance(content, str):
        return True
    return isinstance(content, list) and any(
        isinstance(c, dict) and c.get("type") == "text" for c in content
    )


def turn_texts(lines: list[str]) -> list[str]:
    """最後のユーザープロンプトより後に Claude が書いた text のブロックを、書いた順に返す。"""
    texts: list[str] = []
    for line in lines:
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        if not isinstance(entry, dict):
            continue
        if is_user_prompt(entry):
            texts = []
            continue
        message = entry.get("message")
        if entry.get("type") != "assistant" or not isinstance(message, dict):
            continue
        content = message.get("content")
        if isinstance(content, list):
            texts += [
                c["text"]
                for c in content
                if isinstance(c, dict)
                and c.get("type") == "text"
                and isinstance(c.get("text"), str)
            ]
    return texts


def main() -> None:
    try:
        payload: Any = json.loads(sys.stdin.read())
    except ValueError:
        return
    if not isinstance(payload, dict) or payload.get("stop_hook_active"):
        return
    if os.environ.get("CLAUDE_JA_REPLY_DISABLE") == "1":
        return
    transcript = payload.get("transcript_path")
    if not isinstance(transcript, str) or not Path(transcript).is_file():
        return
    lines = Path(transcript).read_text(encoding="utf-8", errors="replace").splitlines()
    for text in turn_texts(lines):
        rewrite, kana, words = needs_rewrite(text)
        if not rewrite:
            continue
        print(
            json.dumps(
                {"decision": "block", "reason": REASON.format(kana=kana, words=words)},
                ensure_ascii=False,
            )
        )
        return


if __name__ == "__main__":
    # Stop hook は失敗しても返答を止めない
    with contextlib.suppress(Exception):
        main()
