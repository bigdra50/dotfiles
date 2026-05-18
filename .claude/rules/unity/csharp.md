---
paths: "**/Assets/**/*.cs"
---

# Unity C#

## アーキテクチャ

- MonoBehaviourは薄く保つ（ロジックは別クラスへ）
- ScriptableObjectで設定・データを外部化
- VContainer/ZenjectでDI
- Assembly Definitionで依存関係を明示

## Assertion と例外

`UnityEngine.Assertions.Assert` で事前条件・不変条件を表明する。
`UNITY_ASSERTIONS` 制御で Development Build / Editor のみ動作し、リリースから除去される。

使い分け:

| 対象 | 推奨 | 例 |
|------|------|-----|
| `[SerializeField]` 必須参照の設定漏れ | `Assert.IsNotNull` | `Awake` 冒頭でチェック |
| 同 GameObject 上の必須コンポーネント | `Assert.IsNotNull` + `RequireComponent` | 設計上の不変条件 |
| 内部メソッドの引数事前条件 | `Assert` | 呼び出し側のバグを早期検出 |
| `public` API の引数検証 | `ArgumentNullException` 等 | 境界で契約を表明 |
| `FindObjectOfType` / `Physics.Raycast` / `TryGetComponent` | `if` 分岐 | 失敗が通常フロー |
| 外部入力（ユーザー、ネット、I/O、API） | `if` 分岐 + Result/例外 | リカバリ必須 |

原則:

- 「null なら 100% バグ」= Assert、「null があり得る正常状態」= if 分岐
- Assert は副作用を持たせない（評価式に状態変化を入れない）
- メソッド冒頭で事前条件をまとめて表明（防御的プログラミング）
- `public` 境界は `ArgumentNullException.ThrowIfNull(arg)` を優先
- `Debug.Assert` (System.Diagnostics) ではなく `UnityEngine.Assertions.Assert` を使う

## 非同期処理

- UniTaskを優先（Coroutineより）
- CancellationTokenを適切に伝播
- async voidは避ける（UniTaskVoidを使用）

## パフォーマンス

- Update内でのアロケーションを避ける
- GetComponentはキャッシュ
- LINQのGCに注意（ホットパスでは避ける）

## ドメインリロード無効化対応

Domain Reload 無効時にも正しく動作する実装にする。

- 静的フィールドは原則使用しない（DIで解決）
- やむを得ず使う場合は `[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]` でリセット
- 静的イベントは `OnEnable` で `-=` してから `+=`、`OnDisable` で `-=`
- R3/UniRxの購読は `OnDestroy` で確実にDispose
