# Functional Programming Principles

関数型プログラミングの5原則。SOLID原則と同様に、保守性・予測可能性・テスト容易性を高める。

## 1. 不変性（Immutability）

データを変更せず、新しいデータを生成する。

- 変数の再代入を避ける
- コレクションの破壊的操作を避ける
- 状態変更が必要な場合は新しいインスタンスを返す

```
// Bad: 破壊的変更
list.Add(item);

// Good: 新しいコレクションを生成
var newList = list.Append(item);
```

## 2. 純粋関数（Pure Functions）

同じ入力には常に同じ出力を返し、副作用を持たない。

- 外部状態を参照しない
- 外部状態を変更しない
- I/O操作を含まない

```
// Bad: 外部状態に依存
int Calculate() => baseValue * multiplier;

// Good: 引数のみに依存
int Calculate(int baseValue, int multiplier) => baseValue * multiplier;
```

## 3. 関数合成（Function Composition）

小さな関数を組み合わせて複雑な処理を構築する。

- 単一責務の小さな関数を作る
- パイプライン形式で処理を連結
- 中間状態を最小化

```
// 小さな関数を合成
var result = data
    .Select(Normalize)
    .Where(IsValid)
    .Select(Transform);
```

## 4. 高階関数（Higher-Order Functions）

関数を引数として受け取る、または関数を返す。

- 振る舞いをパラメータ化
- 共通パターンを抽象化
- 依存性の注入に活用（DIPに相当）

```
// 振る舞いを引数で受け取る
T[] Filter<T>(T[] items, Func<T, bool> predicate)
```

## 5. 参照透過性（Referential Transparency）

式をその評価結果で置き換えても動作が変わらない。

- キャッシュ・メモ化が安全に適用可能
- テストが容易（入力と出力の検証のみ）
- 並列実行が安全

```
// 参照透過: Add(2, 3) は常に 5 に置換可能
int Add(int a, int b) => a + b;

// 非参照透過: 呼び出しごとに結果が変わる
int GetCurrentHour() => DateTime.Now.Hour;
```

## 原則間の関係

```
純粋関数 + 不変性 = 参照透過性
    │
    ├─→ テスト容易性
    ├─→ 並列安全性
    └─→ 予測可能性

高階関数 + 関数合成 = 抽象化と再利用
    │
    ├─→ DRY
    └─→ 保守性
```

## 副作用の分離

純粋な関数と副作用を持つ処理を分離する。

```
[純粋なコア]  ←──  [副作用のシェル]
   │                    │
   │                    ├─ I/O
   │                    ├─ DB
   └── ビジネスロジック   └─ 外部API
```

- ビジネスロジックは純粋関数で実装
- I/O・DB・外部APIとの通信はアプリケーション境界に配置
- 「Functional Core, Imperative Shell」パターン
