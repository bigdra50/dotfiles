#!/usr/bin/env python3
"""
X Research Agent - Twitter/Xからsite:x.com検索で情報収集するエージェント

使用方法:
    uv run main.py "Claude Codeのauto compactについて調べて"
    uv run main.py --topic "React Server Components" --lang ja
    uv run main.py --topic "React" --log-dir ./logs  # ログをファイルに保存
"""

import argparse
import asyncio
import sys
from datetime import datetime
from pathlib import Path
from typing import TextIO

from claude_agent_sdk import (
    ClaudeAgentOptions,
    ClaudeSDKClient,
    AssistantMessage,
    UserMessage,
    TextBlock,
    ToolUseBlock,
    ToolResultBlock,
    CLINotFoundError,
    ProcessError,
)


SYSTEM_PROMPT = """\
あなたはX(Twitter)リサーチの専門家です。Web検索を使ってX/Twitterから情報を収集します。

## 重要な制約
**ツール呼び出しは必ず1つずつ逐次実行してください。**
並列実行するとAPIエラーが発生します。1つのツール呼び出しが完了してから次を実行してください。

## 調査手順

### Phase 1: 初期検索（逐次実行）
以下のクエリを1つずつ順番に実行:
1. `site:x.com "キーワード1" "キーワード2"` (完全一致・日本語)
2. `site:x.com キーワード1 キーワード2` (部分一致・日本語)
3. `site:x.com "keyword1" "keyword2"` (完全一致・英語)
4. `site:x.com keyword1 keyword2` (部分一致・英語)

注意: `site:twitter.com`は結果が少ない。`site:x.com`を使用。

### Phase 2: 結果の分析
検索結果から抽出:
1. ツイートURL: `x.com/{username}/status/{id}`
2. 投稿者: @ハンドル名
3. 要約: ツイート本文の抜粋
4. 外部リンク: ブログ記事、GitHub Issue等

### Phase 3: 詳細情報の取得（逐次実行）
ツイートが外部コンテンツを参照している場合、WebFetchで1つずつ取得。
優先順位:
1. Zenn/Qiita/dev.to などの技術ブログ
2. GitHub Issues/Discussions
3. 公式ドキュメント

X/Twitterページ直接取得は認証要求でブロックされるため、関連ブログ経由で詳細取得。

### Phase 4: 結果の整理（必須）
**重要: 検索完了後、必ず以下の形式でレポートを出力してください。レポートなしで終了しないでください。**

検索は最大10回程度に抑え、十分な情報が集まったらレポート作成に移行してください。

以下の形式で報告:

## [トピック] に関するX調査結果

### 主要な発見
- [@username](URL): "ツイート要約"

### 詳細情報（外部ソース）
- [記事タイトル](URL): 内容の要約

### 制限事項
- 画像内容は未取得
- [その他の制限]

## 制約
- リアルタイム性なし（インデックス遅延）
- スレッド全体・リプライは取得しにくい
- 画像・動画の内容は直接取得不可
- エンゲージメント数は不明
"""


async def run_research(topic: str, lang: str = "both") -> None:
    """X Researchエージェントを実行"""

    # プロンプト構築
    if lang == "ja":
        prompt = f"以下のトピックについてX(Twitter)で日本語の情報を調査してください: {topic}"
    elif lang == "en":
        prompt = f"Research the following topic on X (Twitter) in English: {topic}"
    else:
        prompt = f"以下のトピックについてX(Twitter)で日本語と英語両方で調査してください: {topic}"

    options = ClaudeAgentOptions(
        system_prompt=SYSTEM_PROMPT,
        allowed_tools=["WebSearch", "WebFetch"],
        permission_mode="acceptEdits",
        max_turns=10,
    )

    print(f"\n{'='*60}")
    print(f"X Research Agent - トピック: {topic}")
    print(f"{'='*60}\n")

    try:
        async with ClaudeSDKClient(options=options) as client:
            await client.query(prompt)

            async for message in client.receive_response():
                if isinstance(message, AssistantMessage):
                    for block in message.content:
                        if isinstance(block, TextBlock):
                            print(block.text, end="", flush=True)
                        elif isinstance(block, ToolUseBlock):
                            print(f"\n[ツール使用: {block.name}]", flush=True)

            print("\n")

    except CLINotFoundError:
        print("エラー: Claude Code CLIがインストールされていません。", file=sys.stderr)
        print("インストール: npm install -g @anthropic-ai/claude-code", file=sys.stderr)
        sys.exit(1)
    except ProcessError as e:
        print(f"エラー: プロセスが失敗しました (exit code: {e.exit_code})", file=sys.stderr)
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="X(Twitter)からsite:x.com検索で情報収集するエージェント"
    )
    parser.add_argument(
        "topic",
        nargs="?",
        help="調査するトピック"
    )
    parser.add_argument(
        "--topic", "-t",
        dest="topic_flag",
        help="調査するトピック（位置引数の代替）"
    )
    parser.add_argument(
        "--lang", "-l",
        choices=["ja", "en", "both"],
        default="both",
        help="検索言語 (ja: 日本語, en: 英語, both: 両方)"
    )
    parser.add_argument(
        "--log-dir",
        type=Path,
        default=None,
        help="ログ出力ディレクトリ（指定時のみファイル出力）"
    )

    args = parser.parse_args()

    # トピックの取得（位置引数またはフラグ）
    topic = args.topic or args.topic_flag
    if not topic:
        parser.error("トピックを指定してください")

    asyncio.run(run_research(topic, args.lang, args.log_dir))


if __name__ == "__main__":
    main()
