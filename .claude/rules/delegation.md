# AI委譲ルール

Claude Code (Opus) が実装を `cursor-agent`、レビュー/分析を `copilot` に委譲する判断基準と運用方針。
委譲は `Agent` ツール (`subagent_type: cursor-agent` または `copilot`) で行う。

## 委譲先の使い分け

| タスク種別 | 委譲先 | モデル | 主な理由 |
| --- | --- | --- | --- |
| 実装 (機能追加・修正・リファクタ) | `cursor-agent` | composer-2.5-fast | 定型実装の待ち時間が短い |
| レビュー・複雑な思考 (設計分析・難バグ調査・第二の意見) | `copilot` | gpt-5.5 (必要なら `--effort high`) | 設計比較と原因分析に使う |

新しい委譲先を追加する場合は、得意領域・禁止事項・フォールバック方針をこの表に追記する。
実装の既定は `cursor-agent`、レビューの既定は `copilot` のままにする。

## 委譲する判断基準

- 実装: 3 ファイル以上の編集、既存パターンに沿った反復編集、テンプレートに沿った機能追加
- レビュー/思考: 設計の良し悪し判断、subtle なバグの原因分析、複数案の比較、自分の判断の裏取り
- 仕様判断を含むタスクは Claude Code 側で設計を固めてから委譲する

## 委譲しないケース

- ユーザーが Claude Code に直接やらせたいと明示しているとき
- 1 ファイル・1〜数行の修正
- 対話的に試行錯誤しながら進めるとき
- 委譲先がレート制限・認証エラーで動かないとき (Claude Code が自分で引き継ぐ)

## 委譲時に要求する返却フォーマット

サブエージェントの返却テキストは Claude Code のコンテキストに直接乗るため、出力を以下に揃えるよう指示する。

- 要約 (1〜3 行)
- 変更ファイルパス一覧 (実装系の場合)
- 未解決の質問・前提・トレードオフ
- 必要に応じて該当箇所の `file:line` 引用

## cursor-agent の運用

- 既定モデル: `composer-2.5-fast` 固定 (体感速度優先)
- rate limit / unavailable 時はフォールバックせず Claude Code に return する
- 分析のみは `--mode ask` / `--mode plan`、実装は `--force` を付ける
- 詳細は `~/.claude/agents/cursor-agent.md`

## copilot の運用

- 既定モデル: `gpt-5.5`
- レビュー/分析は read-only (`--no-ask-user`)、`--allow-all-tools` は実装を明示的に委譲したときのみ
- 推論を深めたいときは `--effort high`
- Anthropic 系モデル (claude-opus-4.x) を指定すると Claude と同系統の視点になるので、第二意見目的では GPT 系を優先する
- 詳細は `~/.claude/agents/copilot.md`
