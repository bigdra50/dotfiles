# Unity コンソールログ管理コマンド

Unity エディターのコンソールログを管理・確認するコマンドです。

## 引数:
- `--clear` - コンソールログをクリア
- `--current` - 現在のコンソールログを表示
- `--compile` - コンパイルエラー・警告のみを表示
- 引数なし - デフォルトは `--current` と同じ動作

## ワークフロー:

### --clear オプション:
1. **ログクリア実行**
   - `mcp__unity-natural-mcp__ClearConsoleLogs` を実行
   - Unity エディターのコンソールを完全にクリア

2. **確認メッセージ**
   - クリア完了の報告

### --current オプション:
1. **現在のログ取得**
   - `mcp__unity-natural-mcp__GetCurrentConsoleLogs` を実行
   - デフォルトで最新20件、最初の1行のみ表示

2. **ログの整形表示**
   - エラー: 🔴 赤色で表示
   - 警告: 🟡 黄色で表示  
   - 通常ログ: ⚪ 白色で表示

3. **要約情報**
   - エラー、警告、ログの件数を表示

### --compile オプション:
1. **コンパイルログ取得**
   - `mcp__unity-natural-mcp__GetCompileLogs` を実行
   - コンパイルエラーと警告のみを抽出

2. **エラー詳細表示**
   - ファイル名と行番号を含む完全なエラーメッセージ
   - エラーの重要度順にソート

3. **修正提案**
   - 一般的なコンパイルエラーに対する簡単な修正提案

## 詳細オプション（将来の拡張用）:
- `--filter <regex>` - 正規表現でログをフィルタリング
- `--count <n>` - 表示するログの件数を指定（デフォルト: 20）
- `--full` - ログメッセージ全体を表示（デフォルトは最初の1行）
- `--watch` - ログを継続的に監視（実装予定）

## エラーハンドリング:
- Unity エディターが起動していない場合
- コンソールログへのアクセスエラー
- 無効なオプション指定

## 使用例:
```bash
# 現在のログを確認
claude /console
claude /console --current

# ログをクリア
claude /console --clear

# コンパイルエラーを確認
claude /console --compile

# 将来の拡張例
claude /console --current --count 50
claude /console --current --filter "error"
```

## 関連コマンド:
- `/refresh` - アセット更新とコンパイル実行
- `/unity-test` - Unity テスト実行
- `/unity-fix` - Unity エラー自動修正