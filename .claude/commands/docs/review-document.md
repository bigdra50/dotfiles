---
allowed-tools: [Read, TodoWrite]
description: Review document quality based on specified guidelines and suggest improvements
model: sonnet
---

# 文書レビュー

指定されたガイドラインに基づいて文書の品質をレビューし、改善点を提案します。

## デフォルトガイドライン

@docs/documentation/anti-ai-writing.md

## ワークフロー

1. **ガイドライン読み込み**
   - デフォルトガイドラインの読み込み
   - 追加指定されたガイドラインの読み込み
   - レビュー基準の統合

2. **文書解析**
   - 対象文書の読み込み
   - 構造と内容の分析
   - 文体と表現の確認

3. **ガイドライン適用**
   - 読み込んだガイドラインに基づく検査
   - 問題点の特定と分類
   - 改善提案の生成

4. **レビュー結果出力**
   - 問題点の整理と提示
   - 具体的な改善提案
   - 評価サマリー

## 出力形式

### 評価サマリー
- 適用したガイドライン一覧
- 検出された問題の概要
- 改善の優先度

### 詳細レビュー
- 行番号付きの具体的指摘
- ガイドライン違反の説明
- 改善提案と修正例

## エラーハンドリング

- 指定ファイルが見つからない場合
- 読み込み権限がない場合
- 対応していないファイル形式の場合
- ガイドラインファイルの読み込みエラー

## 使用例

```bash
# デフォルトガイドラインでレビュー
claude /review-document README.md

# 追加ガイドラインを指定
claude /review-document --guidelines @docs/coding-standards.md document.md

# 複数ファイルのレビュー
claude /review-document docs/*.md
```

## 使用方法

$ARGUMENTS が提供された場合、指定されたファイルをレビューします。
`--guidelines` オプションで追加のガイドラインを指定できます。
引数がない場合は、カレントディレクトリの文書ファイルを対象とします。