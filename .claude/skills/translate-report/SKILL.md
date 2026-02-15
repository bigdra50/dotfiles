---
name: translate-report
description: HTMLレポートファイルをインプレースで多言語翻訳する。HTMLの構造・CSS・JavaScriptを保持したまま、表示テキストのみを翻訳。/insights等で生成されたHTMLレポートの翻訳に使用。
  Use for: "レポート翻訳", "HTMLを日本語に", "translate report", "レポートを翻訳して"
allowed-tools: Read, Edit, Write, Glob
---

# HTMLレポート翻訳

## ワークフロー

1. 対象ファイルを`Read`で読み込む
2. HTML構造を解析し、翻訳対象テキストを特定
3. `Write`でファイル全体をインプレース上書き（元ファイルを直接更新）

## 翻訳ルール

- HTML構造、CSS、JavaScriptは変更しない
- `<title>`、見出し、ラベル、説明文、ボタンテキスト等の表示テキストを翻訳
- `data-text`属性内のテキストも翻訳対象
- JS内の動的ラベル文字列（`label: "Morning (6-12)"`等）も翻訳
- コピーボタンの確認テキスト（`Copied!`等）も翻訳
- 技術用語（Bash, Read, Edit, TodoWrite等のツール名）はそのまま保持
- プロンプト例のコードブロック内は翻訳しない（実行用のため英語のまま）
- CSSクラス名、id、HTMLタグは変更しない
- 数値データ、パーセンテージ、日付フォーマットはそのまま保持

## デフォルト

- 翻訳先言語: 日本語（ユーザーが別言語を指定しない限り）
- 対象パス: `$ARGUMENTS`（引数にファイルパスが含まれる場合）

## 出力

翻訳完了後、変更したファイルパスを報告。
