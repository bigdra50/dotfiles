---
paths: "**/*.go"
---

# Go テストルール

- 実装ではなく振る舞いをテストする
- テーブル駆動テストを基本とする
- 比較には `go-cmp` (`cmp.Diff`) を使う
- ヘルパー関数では必ず `t.Helper()` を呼ぶ
- クリーンアップは `t.Cleanup()` を使う
- テスト名: `Test<関数名><シナリオ>`、サブテスト名は説明的に
- モック: `github.com/ovechkin-dm/mockio` を使用
- ゴールデンファイルは `testdata/golden/` に配置
