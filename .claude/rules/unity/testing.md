---
paths: "**/Assets/**/*.cs"
---

# Unity Testing Guidelines

## 原則

- 実装ではなく振る舞いをテストする（リトマス試験: テスト失敗時にユーザーにとって何が壊れたか説明できるか？）
- 可能な限り本物のプロダクトコードを使う。テストダブルはやむを得ないときのみ

## 構造

- Editor/ 下のコード → `Tests/Editor/` (Edit Mode tests)
- Runtime/ 下のコード → `Tests/Runtime/` (Play Mode tests)
- テストダブルは `Tests/Editor/TestDoubles/` or `Tests/Runtime/TestDoubles/`

## 命名

- テストアセンブリ: テスト対象 + ".Tests"
- テストクラス: テスト対象 + "Test"
- テストメソッド: `メソッド名_条件_期待結果` (e.g., `TakeDamage_WhenHealthIsZero_CharacterDies`)
- 変数: テスト対象=`sut`、実測値=`actual`、期待値=`expected`
- テストダブル: xUTP準拠で `stub`, `spy`, `dummy`, `fake`, `mock` の接頭辞

## 設計

- NUnit3 + Unity Test Framework。`[TestFixture]` 必須
- AAA (Arrange/Act/Assert) パターン。セクション間は空行、コメント不要
- Assert は1テスト1つ。制約モデル(`Assert.That`)を使用。`message`引数は不要
- テストコードに `if`/`switch`/`for`/`foreach`/三項演算子を使わない
- `TestCase`/`TestCaseSource`/`Values` でパラメータ化を積極活用
- オブジェクト生成は creation method pattern (e.g., `CreateSystemUnderTestObject()`)
- `GameObject` 生成時はテストメソッドに `[CreateScene]` 属性
- `LogAssert` は避け、Spy を使う
- 非同期: `Delay`/`Wait` を避ける。1フレーム待ちは `yield return null`
- 非同期例外検証: `Throws` 制約ではなく try-catch + `Assert.Fail` パターン（UTF制限）
- ゴールデンファイルは `Tests/TestData/golden/` に配置

## テスト実行

テスト実行コマンドはプロジェクトの CLAUDE.md / rules を参照すること（プロジェクトにより異なる）。
