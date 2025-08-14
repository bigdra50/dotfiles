# unity-fix

Unity プロジェクトのコンソールエラーを包括的に分析し、可能な問題の自動修正を行うコマンドです。UnityNaturalMCPツールを活用してエラーパターンの検出、分類、解決策の提案、および自動修正を実行します。

## ワークフロー:

1. **Unity環境の確認**
   - UnityNaturalMCPツールの利用可能性確認
   - Unityプロジェクトが開いているかチェック
   - アセットの状態確認

2. **ログ取得と前処理**
   - `GetCurrentConsoleLogs` でコンソールログを取得
   - ログレベル別分類（Error、Warning、Info）
   - 重複ログの除去と頻度カウント

3. **エラー分析とパターン検出**
   - エラータイプの自動分類
     - コンパイルエラー（Syntax、Type、Reference）
     - ランタイムエラー（NullReference、IndexOutOfRange、Missing Component）
     - アセットエラー（Missing Reference、Import Error）
     - パフォーマンス警告
   - スタックトレース解析
   - 既知のパターンマッチング

4. **自動修正の実行**
   - **Missing Reference修正**
     - 削除されたオブジェクトやコンポーネントの参照クリア
     - 類似名のアセットで自動置換提案
   - **Import Setting修正**
     - テクスチャやオーディオの設定最適化
     - プラットフォーム固有の設定調整
   - **Script Reference修正**
     - 移動されたスクリプトの参照更新
     - Assembly Definition の依存関係修正
   - `RefreshAssets` でアセット更新を実行

5. **問題の分析と報告**
   - 修正可能/修正不可の問題分類
   - 重要度とリスクレベルの評価
   - 解決策の詳細提案
   - パフォーマンス影響の分析

6. **結果出力と次のアクション**
   - 修正結果のサマリー表示
   - 未解決問題の優先順位付け
   - 必要に応じて詳細レポートをファイル出力
   - オプションで `ClearConsoleLogs` を実行

## 引数とオプション:

- `--fix-level [basic|aggressive]`: 自動修正の積極度
  - `basic`: 安全な修正のみ（Missing Reference等）
  - `aggressive`: より積極的な修正（設定変更含む）
- `--filter [error|warning|all]`: 分析対象の指定
- `--report [console|file|both]`: 結果出力形式
- `--clear-after`: 分析後にコンソールログをクリア
- `--backup`: 修正前に自動バックアップを作成

## 自動修正可能な問題例:

### 即座に修正可能
- Missing MonoBehaviour references
- 削除されたGameObjectへの参照
- Import設定の基本的な問題
- 非推奨APIの使用警告

### 提案型修正
- パフォーマンス最適化（設定調整）
- アセット配置の最適化提案
- メモリ使用量削減の提案

### 手動対応が必要
- 複雑なスクリプトエラー
- 論理的なバグ
- アーキテクチャ設計の問題

## エラーハンドリング:

- UnityNaturalMCPツールが利用できない場合
- Unityプロジェクトが開いていない場合
- ログ取得に失敗した場合
- 自動修正中にアセットが破損した場合（バックアップからの復元）
- 権限エラーでファイル修正ができない場合
- 大量のエラーでメモリ不足が発生した場合

## 使用例:

```bash
# 基本的なエラー分析と安全な自動修正
claude /unity-fix

# 積極的な自動修正を含む完全分析
claude /unity-fix --fix-level aggressive --clear-after

# エラーのみフィルタして詳細レポート出力
claude /unity-fix --filter error --report file

# バックアップ付きで修正実行
claude /unity-fix --backup --fix-level basic
```

## 出力例:

```
🔍 Unity エラー分析結果

📊 ログサマリー:
- エラー: 12件 (修正済み: 8件)
- 警告: 23件 (修正済み: 15件)
- 重複除去: 45件 → 35件

🔧 自動修正実行:
✅ Missing Reference: 5件修正
✅ Import Settings: 3件最適化
✅ Script References: 2件更新
⚠️  手動確認必要: 2件

🎯 優先対応が必要:
1. [高] NullReferenceException in PlayerController.cs:42
2. [中] Texture import設定の最適化提案
3. [低] 非推奨API使用の警告

💡 最適化提案:
- Build Settingsでの不要シーンの除去
- Audio Clipの圧縮設定見直し
```