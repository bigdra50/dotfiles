---
paths: "**/*.swift"
---

# Swift

## 原則

### 関数型アプローチ
- 純粋関数を優先
- 不変データ構造（let優先、struct活用）
- 副作用を分離
- 型安全性を確保

### ドメイン駆動設計
- 値オブジェクトとエンティティを区別
- 集約で整合性を保証
- ドメインサービスは最終手段

### テスト駆動開発
- Red-Green-Refactorサイクル
- テストを仕様として扱う
- アサートファースト

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

## visionOS / RealityKit固有

- Entityはシンプルに保つ
- Componentで振る舞いを分離
- Systemでロジックを集約
- async/awaitで非同期処理

## 実装手順

1. 型設計 - Protocolとstructを定義
2. 純粋関数から実装 - テストを先に書く
3. 副作用を分離
4. アダプター実装 - 外部依存を抽象化

## エラーハンドリング

- Result型を活用
- throwsは回復可能なエラー
- fatalErrorは開発時のみ
