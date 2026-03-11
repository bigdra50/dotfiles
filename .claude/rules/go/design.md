---
paths: "**/*.go"
---

# Go 設計思想

- Accept interfaces, return structs
- インターフェースは使用する側で定義する（実装側ではない）
- インターフェースは小さく、必要に応じて合成する
- 可変設定には Functional Options パターンを使う
- センチネルエラー(`errors.Is`) とカスタムエラー型(`errors.As`) を使い分ける
- ゼロ値が有用な struct 設計にする
