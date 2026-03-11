---
paths: "**/*.swift"
---

# Swift

## 型設計

- `struct`をデフォルトに（`class`は参照が必要な場合のみ）
- `enum`で状態を表現（Associated Values活用）
- Protocol Oriented Programming
- Genericsで再利用性確保

## コードスタイル

- guard文で早期リターン
- Optional Binding（if let, guard let）
- trailing closureを活用
- Codableでシリアライズ
- Result型を活用。throwsは回復可能なエラー、fatalErrorは開発時のみ

## visionOS / RealityKit

- Entityはシンプルに保つ
- Componentで振る舞いを分離
- Systemでロジックを集約
