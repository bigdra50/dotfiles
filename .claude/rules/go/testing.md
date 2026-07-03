---
paths:
  - "**/*.go"
---

# Go テスト

- 実装ではなく振る舞いをテストする
- テーブル駆動テストを基本とする
- 比較は go-cmp（`cmp.Diff`）
- モックは `github.com/ovechkin-dm/mockio`
- ゴールデンファイルは `testdata/golden/` に配置
- テスト名: `Test<関数名><シナリオ>`、サブテスト名は説明的に
