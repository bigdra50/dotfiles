---
paths:
  - "**/*.go"
  - "**/*.rs"
  - "**/*.ts"
  - "**/*.lua"
  - "**/*.cs"
---

# 設計共通ルール

## SOLID原則

### 単一責任の原則 (SRP)

- クラス/モジュールは1つの責任のみを持つ
- 変更する理由は1つだけであるべき

### 開放閉鎖の原則 (OCP)

- 拡張に対して開いている、修正に対して閉じている
- 既存コードを変更せずに機能追加できる設計

### リスコフの置換原則 (LSP)

- 派生型は基底型と置換可能であるべき
- サブタイプは親の契約を破らない

### インターフェース分離の原則 (ISP)

- クライアントが使わないメソッドへの依存を強制しない
- 大きなインターフェースより小さな専用インターフェース

### 依存性逆転の原則 (DIP)

- 上位モジュールは下位モジュールに依存しない
- 両者とも抽象に依存する

## 関数型プログラミング原則

SOLID原則を関数レベルで実現する手法。

### 不変性（Immutability）

データを変更せず、新しいデータを生成する。

- 変数の再代入を避ける
- コレクションの破壊的操作を避ける
- 状態変更が必要な場合は新しいインスタンスを返す

```csharp
// Bad: 破壊的変更
list.Add(item);

// Good: 新しいコレクションを生成
var newList = list.Append(item);
```

### 純粋関数（Pure Functions）

同じ入力には常に同じ出力を返し、副作用を持たない。

- 外部状態を参照しない
- 外部状態を変更しない
- I/O操作を含まない

```csharp
// Bad: 外部状態に依存
int Calculate() => _baseValue * _multiplier;

// Good: 引数のみに依存
int Calculate(int baseValue, int multiplier) => baseValue * multiplier;
```

### 関数合成（Function Composition）

小さな関数を組み合わせて複雑な処理を構築する。

```csharp
var result = data
    .Select(Normalize)
    .Where(IsValid)
    .Select(Transform);
```

### 高階関数（Higher-Order Functions）

関数を引数として受け取る、または関数を返す。DIPの関数レベル実装。

```csharp
T[] Filter<T>(T[] items, Func<T, bool> predicate)
```

### 参照透過性（Referential Transparency）

式をその評価結果で置き換えても動作が変わらない。

- キャッシュ・メモ化が安全に適用可能
- テストが容易（入力と出力の検証のみ）
- 並列実行が安全

### 副作用の分離

```
[純粋なコア]  ←──  [副作用のシェル]
   │                    │
   │                    ├─ I/O
   │                    ├─ DB
   └── ビジネスロジック   └─ 外部API
```

「Functional Core, Imperative Shell」パターン。

## YAGNI原則

- 「将来必要になるかもしれない」というコードを書かない
- 現在必要な機能のみを実装する
- 未使用のメソッド、フィールド、パラメータは即座に削除
- 意図が不明確なコードを変更する前にユーザーに確認

## 命名規則

### 曖昧な名前を避ける

`check`、`process`、`handle`、`do` のような曖昧な名前を避け、具体的なアクションを説明：

```csharp
// Good
CompareVersion()
ValidateInput()
FetchLatestData()

// Bad
CheckVersion()
ProcessData()
HandleRequest()
```

### 戻り値の型名

```csharp
// Good
VersionCompareResult
ParsedConfig

// Bad
CheckResult
Data
```

## 高凝集度（High Cohesion）

1つのモジュール/コンポーネントは1つの責務に集中する。

判断基準:

- 変更理由が1つだけか（Single Responsibility）
- テストが1つの観点に集中できるか
- 説明が「〜と〜と〜」ではなく「〜」で済むか

## 低結合度（Low Coupling）

モジュール間の依存は最小限かつ明示的にする。

依存の方向性:

```
外部（不安定）  →  ドメイン（安定）
UI層 → ビジネスロジック層 → ドメインモデル
```

依存性注入でテスト可能にする:

```csharp
// Bad: 具体的な実装に依存
public class UserProfile
{
    public User GetUser() => ApiClient.FetchUser();
}

// Good: 抽象に依存
public class UserProfile
{
    private readonly IUserRepository _repository;
    public UserProfile(IUserRepository repository) => _repository = repository;
    public User GetUser() => _repository.GetUser();
}
```

## アンチパターン

避けるべき設計：

- God Class/Component: 1つのクラスが多すぎる責務を持つ
- Feature Envy: 他モジュールのデータに過度に依存
- Shotgun Surgery: 1つの変更で多数のファイルを修正
- Primitive Obsession: 基本型で全てを表現しようとする
