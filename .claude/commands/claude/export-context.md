---
allowed-tools: [Read, TodoWrite]
description: Generate a prompt to transfer current conversation context to another session
model: sonnet
---

# Export Conversation Context

このコマンドは、現在の会話内容を別のClaude Codeセッションに引き継ぐためのプロンプトを生成します。

## ワークフロー

1. **現在の状態を分析**
   - Todo リストの内容を確認
   - 会話の要点を抽出（主要な決定事項、実装内容、課題）
   - 関連ファイルのパスを特定

2. **コンテキストプロンプト生成**
   - 会話の概要をまとめる
   - 完了したタスクと残タスクをリスト化
   - 重要な技術的決定事項を記録
   - 次セッションで必要なファイルパスを列挙

3. **出力フォーマット**
   ```markdown
   # Session Context Transfer

   ## Overview
   [会話の概要]

   ## Completed Tasks
   - [完了したタスク1]
   - [完了したタスク2]

   ## Pending Tasks
   - [残タスク1]
   - [残タスク2]

   ## Key Decisions & Implementation Details
   - [重要な決定事項]
   - [実装の詳細]

   ## Relevant Files
   - /path/to/file1
   - /path/to/file2

   ## Next Steps
   [次に取り組むべきこと]
   ```

## 使用方法

```bash
# 基本的な使用
/export-context

# 特定のファイルに焦点を当てる
/export-context focused on authentication implementation
```

## 注意事項

- 生成されたプロンプトは、新しいセッションの最初のメッセージとして使用してください
- 機密情報が含まれていないか確認してから共有してください
- 大規模な変更の場合は、コミット履歴も参照することを推奨します
