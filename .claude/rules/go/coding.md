---
paths:
  - "**/*.go"
---

# Go

機械検査可能な規約（`%w` ラップ、slog のキー名等）は golangci-lint の設定が正。

- エラーはログ出力と返却のどちらか一方のみ
- 可変設定には Functional Options パターン
