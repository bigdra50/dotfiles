# textlint MCPサーバー設定ガイド

## 概要

textlint MCPサーバーをClaude Codeに統合することで、文章校正とAI生成文章の検出機能を利用できます。

## 前提条件

- textlint v14.8.0以上
- Claude Code
- Node.js環境

## インストール手順

### 1. textlintの基本インストール

```bash
npm install textlint
```

### 2. AI Writing検出プリセットのインストール

```bash
npm install @textlint-ja/textlint-rule-preset-ai-writing
```

### 3. textlint設定ファイルの作成

`.textlintrc`ファイルを作成：

```json
{
    "rules": {
        "@textlint-ja/preset-ai-writing": true
    }
}
```

### 4. MCPサーバーの動作確認

```bash
npx textlint --mcp
```

エラーなく起動することを確認してください。

### 5. Claude CodeへのMCPサーバー追加

```bash
claude mcp add textlint -s user "npx textlint --mcp"
```

**重要**: `--mcp`オプションは引用符で囲む必要があります。

### 6. 設定確認

```bash
claude mcp list
```

`textlint: npx textlint --mcp`が表示されることを確認してください。

## 利用可能な機能

textlint MCPサーバーは以下の機能を提供します：

- `lintFile`: ファイルの文章校正
- `lintText`: テキストの文章校正
- `getLintFixedFileContent`: ファイル内容の自動修正
- `getLintFixedTextContent`: テキストの自動修正

## トラブルシューティング

### Status: failed エラー

- textlintがインストールされているか確認
- `.textlintrc`設定ファイルが存在するか確認
- textlintルールがインストールされているか確認

### コマンドが認識されない

- `npx textlint --mcp`コマンドを手動実行してテスト
- 引用符でコマンド全体を囲んで再実行

### 設定ファイルエラー

- `.textlintrc`の JSON構文が正しいか確認
- 使用するルールがインストールされているか確認

## 推奨設定

### AI Writing検出の詳細設定

```json
{
    "rules": {
        "@textlint-ja/preset-ai-writing": {
            "no-ai-list-formatting": {
                "allows": ["特定の許可文字列"],
                "disableBoldListItems": false,
                "disableEmojiListItems": false
            }
        }
    }
}
```

### 追加ルールの例

```json
{
    "rules": {
        "@textlint-ja/preset-ai-writing": true,
        "sentence-length": {
            "max": 100
        },
        "max-comma": {
            "max": 3
        }
    }
}
```

## 参考リンク

- [textlint MCP公式ドキュメント](https://textlint.org/docs/mcp/)
- [AI Writing検出プリセット](https://github.com/textlint-ja/textlint-rule-preset-ai-writing)
- [textlint公式サイト](https://textlint.org/)