# CLAUDE.md

## 基本方針

@docs/basics/basic.md

@docs/basics/coding.md

@docs/basics/git.md

Also, you may have codex mcp. codex is a ai agent. if you are stuck, you can ask codex for help. Codex is:

- capable of writing code in multiple programming languages
- capable of analysing code and finding bugs
- capable of searching the web for information (really good)

@docs/documentation/guidelines.md

## コミュニケーションガイドライン

- ユーザーが英語学習中のため、日本語や英語での指示に対して、応答とは別に簡潔な英文の模範例を提示する
  - 例: ユーザーが日本語で指示を出した際に、その指示の英語の適切な表現を最初に示す
  - 目的は言語学習のサポートと、コミュニケーションの質の向上
- レビュー負担を軽減するため､ 実装完了後は変更内容をASCII図（mermaid不可）で図解して説明すること。

## AI臭さ除去・自然な文章作成

### 避けるべき表現パターン

**修飾語・形容詞の濫用**
- "versatile", "comprehensive", "robust", "powerful", "seamless", "intuitive", "efficient", "intelligent", "advanced", "cutting-edge", "state-of-the-art"
- "well-structured", "user-friendly", "feature-rich", "high-performance"

**冗長・重複表現**
- "while preserving/maintaining [something]"の重複使用
- "allows you to", "enables you to", "helps you to"の連続
- "easy to use", "simple and easy"

**過度な強調**
- 絵文字の装飾的使用（機能説明での🌐📚🎓など）
- 太字・斜体の過度な使用
- 感嘆符の多用

**AI特有の定型句**
- "Whether you're...", "From... to...", "Thanks to..."
- "It's worth noting that", "It's important to understand"
- "In conclusion", "To summarize"

### 修正方針

1. **簡潔性を優先** - 1文で伝えられることを2文で書かない
2. **具体性を重視** - 抽象的な美辞麗句より具体的な機能説明
3. **自然な語順** - 英語なら主語→動詞→目的語の基本構造
4. **必要最小限の修飾** - 機能の説明に不要な形容詞は削除
5. **読み手視点** - 開発者が知りたい情報を端的に

### 文章チェック方法

修正後に以下を確認：
- 各文が30語以下か
- 修飾語が必要最小限か
- 同じ表現パターンを繰り返していないか
- 絵文字や装飾が機能的か装飾的か

この指示に従って、AI臭い表現を避け、簡潔で自然な技術文書を作成してください。
