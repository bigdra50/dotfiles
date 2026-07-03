---
paths:
  - "**/*.go"
---

# Go

機械検査可能な規約（`%w` ラップ、slog のキー名等）は golangci-lint の設定が正。

- エラーはログするか返すか、どちらか一方のみ
- インターフェースは使用側で定義し、小さく保つ
- 可変設定には Functional Options パターン
- センチネルエラー（`errors.Is`）とカスタムエラー型（`errors.As`）を使い分ける
- ゼロ値が有用な struct 設計にする
- goroutine は `ctx.Done()` で終了を保証する。チャネルの `close` 責任は送信側
