# X Research Agent

X(Twitter)から`site:x.com`検索で情報収集するClaude Agentです。

## 特徴

- **API不要**: 公式Twitter APIを使わず、Web検索経由でツイートを取得
- **コスト$0**: 追加料金なしで利用可能
- **詳細取得**: ツイートが参照するブログ記事をWebFetchで取得

## セットアップ

```bash
# 依存関係のインストール
uv sync

# 認証設定（以下のいずれか）
# 方法1: OAuth Token（推奨）
export CLAUDE_CODE_OAUTH_TOKEN="your_oauth_token"

# 方法2: API Key
export ANTHROPIC_API_KEY="your_api_key"
```

## 使用方法

```bash
# 基本的な使い方
uv run main.py "Claude Codeのauto compactについて"

# 日本語のみで検索
uv run main.py --topic "React Server Components" --lang ja

# 英語のみで検索
uv run main.py -t "Cursor vs Claude Code" -l en
```

## オプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `topic` | 調査するトピック（位置引数） | - |
| `--topic, -t` | 調査するトピック（フラグ） | - |
| `--lang, -l` | 検索言語 (`ja`, `en`, `both`) | `both` |

## 調査手順

1. **Phase 1**: `site:x.com`で複数クエリを並列検索
2. **Phase 2**: ツイートURL、投稿者、要約を抽出
3. **Phase 3**: 関連ブログ記事をWebFetchで詳細取得
4. **Phase 4**: 結果をマークダウン形式で整理

## 制約事項

- リアルタイム性なし（検索エンジンのインデックス遅延）
- スレッド全体・リプライは取得しにくい
- 画像・動画の内容は直接取得不可
- エンゲージメント数（いいね・RT）は不明

## ライセンス

MIT
