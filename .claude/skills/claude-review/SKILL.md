---
name: claude-review
description: |
  Claudeを使った多角的コードレビュー。セキュリティ、パフォーマンス、保守性、設計の4観点で並列分析。
  Use for: "レビューして", "コードレビュー", "多角的に見て", "4観点でレビュー"
allowed-tools: Task, Read, Glob, Grep
user-invocable: true
---

# Claude Multi-Perspective Review

4つの観点からTask toolで並列実行し、統合レポートを生成。

## Usage

```
/claude-review <target>
/claude-review src/auth/
/claude-review 最近の変更
```

## Execution

Task toolで4つの**Explore agent**を並列起動:

```
Task(subagent_type="Explore", prompt="[Security Review] <target>...")
Task(subagent_type="Explore", prompt="[Performance Review] <target>...")
Task(subagent_type="Explore", prompt="[Maintainability Review] <target>...")
Task(subagent_type="Explore", prompt="[Architecture Review] <target>...")
```

## Review Prompts

**Security:**
```
[Security Review] <target>を以下の観点でレビュー:
- 機密情報の露出リスク（APIキー、認証情報等）
- SQLインジェクション、XSS、CSRF等の脆弱性
- 認証・認可の問題
- 入力検証の不備
具体的なファイル:行番号と修正案を提示。
```

**Performance:**
```
[Performance Review] <target>を以下の観点でレビュー:
- N+1クエリ、不要なループ
- メモリリーク、リソース解放漏れ
- キャッシュ活用の機会
- 計算量・アルゴリズム効率
具体的なファイル:行番号と改善案を提示。
```

**Maintainability:**
```
[Maintainability Review] <target>を以下の観点でレビュー:
- コードの可読性、複雑度
- 重複コード、DRY原則違反
- 命名規則、一貫性
- コメント・ドキュメントの適切さ
具体的なファイル:行番号とリファクタリング案を提示。
```

**Architecture:**
```
[Architecture Review] <target>を以下の観点でレビュー:
- 設計パターンの適切な使用
- 責務分離、単一責任原則
- 依存関係、結合度
- 拡張性、テスト容易性
具体的なファイル:行番号と改善案を提示。
```

## Workflow

1. 4つのTask toolを同時に起動（Explore agent）
   - 並列実行で時間短縮
2. 各agentがコードベースを探索・分析
   - 大規模プロジェクトは時間がかかる場合あり
3. 結果を統合してレポート作成

## Output Format

```markdown
# Claude Multi-Perspective Review: <target>

## Summary
| 優先度 | 件数 |
|--------|------|
| Critical/High | X件 |
| Medium | X件 |
| Low | X件 |

## Security
| 優先度 | 問題 | 箇所 |
|--------|------|------|
| High | ... | `file.cs:123` |

## Performance
[結果テーブル]

## Maintainability
[結果テーブル]

## Architecture
[結果テーブル]

## Recommended Actions (Top 10)
1. [Critical] ...
2. [High] ...
```

## Notes

- Explore agentは読み取り専用（ファイル変更なし）
- Claudeの深いコード理解を活用
- /codex-review と併用して複数AI視点を比較可能
