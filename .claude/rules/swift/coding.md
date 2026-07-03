---
paths:
  - "**/*.swift"
---

# Swift

- class は参照セマンティクスが必要な場合のみ。継承はフレームワークが要求する場合に限る
- 状態は enum + Associated Values で表現する
- エラーは Result / throws で表現する。`fatalError` はプログラミングエラーの検出のみ（リカバリ可能なフローに使わない）
