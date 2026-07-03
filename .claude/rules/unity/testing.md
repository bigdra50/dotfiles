---
paths:
  - "**/Assets/**/*.cs"
---

# Unity Testing

詳細な手順・API リファレンスは unity-coding-skills プラグイン（test-designing-guide / test-writing-guide / run-tests）を参照。ここには常時適用する要点のみ書く。

## 原則

- 実装ではなく振る舞いをテストする（リトマス試験: テスト失敗時にユーザーにとって何が壊れたか説明できるか）
- 可能な限り本物のプロダクトコードを使う。テストダブルはやむを得ないときのみ
- private メンバーはテストしない（リフレクション経由も禁止）。internal は `InternalsVisibleTo` + テストに `[Category("Internal")]`
- MonoBehaviour のロジックは Humble Object パターンで抽出してテストする。`MonoBehaviourTest<T>` はライフサイクル進行自体の観察が必要な場合のみ

## 構造とモード

- 実行モードはパスで決まる（属性ではない）: `Tests/Editor/` = Edit Mode、`Tests/Runtime/` = Play Mode
- ランタイムコードのロジックを Edit Mode でテストしない（両モードへの分割は一括実行を妨げ、実機でも実行できない）
- テストダブルは `Tests/Runtime/TestDoubles/`、テストシーンは `Tests/Scenes/`、ゴールデンファイルは `Tests/TestData/golden/`
- `.meta` ファイルは自分で作らない（Unity が生成する）

## 命名

- テストアセンブリ: 対象 + `.Tests`、テストクラス: 対象 + `Test`、名前空間はテスト対象と同一
- Unit テスト: `メソッド名_条件_期待結果`。Integration / Visual verification テストは対象が単一メソッドでないため `条件_期待結果`
- 変数: テスト対象 = `sut`、実測値 = `actual`、期待値 = `expected`
- テストダブルは xUTP 準拠で `stub` / `spy` / `fake` / `mock` / `dummy` の接頭辞

## モダンな書き方（訓練データに多い古いパターンを使わない）

| 古い（禁止） | 現行 |
|------|------|
| `[UnityTest] IEnumerator` | `[Test] async Task`（UTF 1.4.6+ が必要） |
| `yield return null` で1フレーム待ち | `await Awaitable.NextFrameAsync()` |
| `Assert.AreEqual` 等の classic モデル | `Assert.That(actual, Is.EqualTo(expected))` 制約モデルのみ |
| `Task.Delay` / 固定時間待ち | 状態遷移は `WaitUntil` + `[Timeout]`、出現待ちは `GameObjectFinder` のポーリング |

- `[TestCase]` / `[TestCaseSource]` は `[UnityTest]` と併用不可。async `[Test]` とは併用可
- 非同期メソッドの例外検証は `Throws` 制約ではなく try-catch + `Assert.Fail`（UTF の制限）

## 設計

- `[TestFixture]` 必須。AAA (Arrange/Act/Assert) はセクション間を空行で区切る（コメント不要）
- Assert は原則1テスト1つ、`message` 引数なし。例外: 状態遷移後の複数プロパティを同時検証する場合は複数可、その場合は各 `Assert.That` に `message` 必須
- テストコードに `if` / `switch` / `for` / `foreach` / 三項演算子を書かない（直線コードのみ）
- 類似ケースは `TestCase` / `TestCaseSource` / `Values` でパラメータ化
- 外部状態（シーン、アセット）の事前条件は `Assert.That` ではなく `Assume.That`（環境問題を inconclusive として実失敗と区別）
- オブジェクト破棄の検証は `Is.Destroyed`（test-helper）
- `GameObject` 生成時は `[CreateScene]`。複数テストで共有するセットアップはテストクラスと 1:1 のシーンファイル + `[LoadScene]`
- オブジェクト生成は creation method パターン（例: `CreateSystemUnderTest()`）

## UI テスト（test-helper.ui）

- 探索は `GameObject.Find` ではなく `GameObjectFinder`（出現までポーリング + 到達可能性・被り検証、失敗時は明確な `TimeoutException`）
- 操作は `onClick.Invoke()` やフィールド直接代入ではなく operator（`UguiClickOperator` / `UguiTextInputOperator` 等）で `EventSystem` 経由にする
- UI 操作・スクリーンショットを含むテストクラスには `[FocusGameView]`（ロジックのみのクラスには付けない）
- レイアウト検証は `Canvas.ForceUpdateCanvases()` + 1フレーム待ちの後に assert する

## ログとスパイ

- プロダクトコードのログ検証は `LogAssert` ではなく Spy logger を注入する。`LogAssert` は UnityEngine / サードパーティ発のログにのみ使用可
- Spy MonoBehaviour には `[AddComponentMenu("/")]` を付け、呼び出しを public プロパティに記録する（`Debug.Log` + `LogAssert` にしない）

## テスト実行

テスト実行コマンドはプロジェクトの CLAUDE.md / rules を参照すること（プロジェクトにより異なる）。
