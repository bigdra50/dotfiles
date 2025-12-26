---
paths: "**/*.py"
---

# Python

## 原則

### 関数型アプローチ
- 純粋関数を優先
- 不変データ構造（tuple, frozenset, dataclass(frozen=True)）
- 副作用を分離
- 型ヒントを必須

### ドメイン駆動設計
- 値オブジェクトとエンティティを区別
- 集約で整合性を保証
- ドメインサービスは最終手段

### テスト駆動開発
- Red-Green-Refactorサイクル
- pytestを使用
- アサートファースト

## 型設計

- `dataclass(frozen=True)`で不変な値オブジェクト
- `TypedDict`で辞書の型付け
- `Protocol`でstructural subtyping
- `Literal`, `Union`で厳密な型表現

## コードスタイル

- 早期リターンで条件分岐をフラット化
- リスト内包表記を適切に使用（複雑なら通常ループ）
- f-stringでフォーマット
- Pathlib優先（os.path より）

## ツール

- ruffでlint/format
- mypyで型チェック
- pytestでテスト

## 実装手順

1. 型設計 - Protocol/dataclassを定義
2. 純粋関数から実装 - テストを先に書く
3. 副作用を分離
4. アダプター実装 - 外部依存を抽象化

## エラーハンドリング

- カスタム例外クラスを定義
- Result型パターンを検討（returns等）
- bare exceptは禁止
