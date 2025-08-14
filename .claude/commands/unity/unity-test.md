# unity-test

Unity プロジェクトのテストを包括的に実行し、結果を詳細に分析するコマンドです。UnityNaturalMCPツールを活用してEditModeテストとPlayModeテストを実行し、テスト結果の詳細な分析とレポートを提供します。

## ワークフロー:

1. **Unity環境の確認**
   - UnityNaturalMCPツールの利用可能性確認
   - Unityプロジェクトが開いているかチェック
   - Test Runnerの設定確認

2. **テスト実行の準備**
   - 現在のコンソールログを取得（実行前の状態確認）
   - `RefreshAssets` でアセットを最新状態に更新
   - テストモードの選択または引数による指定

3. **テストの実行**
   - **EditModeテスト**: `RunEditModeTests` でエディタモードテストを実行
   - **PlayModeテスト**: `RunPlayModeTests` でプレイモードテストを実行
   - **両方**: 順序立てて両モードのテストを実行
   - 実行中の進捗状況をリアルタイム表示

4. **結果の分析とレポート**
   - テスト実行後のコンソールログを取得
   - 成功・失敗・スキップされたテストの集計
   - 実行時間とパフォーマンス情報の分析
   - 失敗したテストの詳細情報抽出

5. **詳細レポートの表示**
   - テスト結果のサマリー表示
   - 失敗テストのエラーメッセージとスタックトレース
   - パフォーマンス警告やメモリ使用量の情報
   - 改善提案とネクストアクション

6. **オプション処理**
   - テスト完了後のコンソールログクリア
   - 詳細レポートのファイル出力
   - CI/CD環境での結果コード出力

## 引数とオプション:

- `--mode [edit|play|both]`: 実行するテストモード（デフォルト: both）
- `--assembly [assembly-name]`: 特定のアセンブリのテストのみ実行
- `--category [category-name]`: 特定のカテゴリのテストのみ実行
- `--filter [test-name-pattern]`: テスト名パターンでフィルタリング
- `--timeout [seconds]`: テスト実行のタイムアウト設定
- `--report [console|file|both]`: 結果出力形式
- `--clear-after`: テスト完了後にコンソールログをクリア
- `--ci-mode`: CI/CD環境用の簡潔な出力形式

## テスト結果の分析項目:

### パフォーマンス分析
- 各テストの実行時間
- メモリ使用量の変化
- GC（ガベージコレクション）の発生頻度
- フレームレート（PlayModeテスト）

### エラー分析
- 失敗テストの分類（Assert失敗、例外、タイムアウト）
- エラーパターンの特定
- 共通する失敗原因の抽出
- 依存関係の問題検出

### 品質指標
- テストカバレッジ情報（利用可能な場合）
- テストの安定性評価
- 実行時間の傾向分析

## エラーハンドリング:

- UnityNaturalMCPツールが利用できない場合
- Unityプロジェクトが開いていない場合
- Test Runnerが正しく設定されていない場合
- テスト実行中にUnityがクラッシュした場合
- テストアセンブリが見つからない場合
- タイムアウトでテストが中断された場合
- メモリ不足でテストが失敗した場合

## 使用例:

```bash
# 全テストを実行
claude /unity-test

# EditModeテストのみ実行
claude /unity-test --mode edit

# 特定アセンブリのテストを実行
claude /unity-test --assembly "MyProject.Tests"

# パターンマッチでテストをフィルタリング
claude /unity-test --filter "*Integration*" --mode play

# CI/CD環境での実行
claude /unity-test --ci-mode --clear-after --timeout 600

# 詳細レポートをファイル出力
claude /unity-test --report file --mode both
```

## 出力例:

```
🧪 Unity テスト実行開始

📋 実行設定:
- モード: EditMode + PlayMode
- アセンブリ: すべて
- タイムアウト: 300秒

🔄 EditModeテスト実行中...
✅ EditModeテスト完了: 45件成功, 2件失敗, 1件スキップ

🎮 PlayModeテスト実行中...
✅ PlayModeテスト完了: 23件成功, 0件失敗, 0件スキップ

📊 テスト結果サマリー:
- 総テスト数: 71件
- 成功: 68件 (95.8%)
- 失敗: 2件 (2.8%)
- スキップ: 1件 (1.4%)
- 実行時間: 2分34秒

❌ 失敗したテスト:
1. PlayerControllerTest.Jump_ShouldMoveUpward
   - Assert.AreEqual failed. Expected: 5, Actual: 4.8
   - Assets/Tests/PlayerControllerTest.cs:line 42

2. DatabaseManagerTest.SaveData_ShouldPersist
   - NullReferenceException: Object reference not set
   - Assets/Tests/DatabaseManagerTest.cs:line 28

🚀 パフォーマンス情報:
- 平均実行時間: 2.2秒/テスト
- メモリ使用量ピーク: 245MB
- GC発生回数: 12回

💡 改善提案:
- PlayerControllerのジャンプ力計算を確認
- DatabaseManagerの初期化処理を見直し
- メモリ使用量の最適化を検討
```