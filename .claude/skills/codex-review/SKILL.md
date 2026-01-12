---
name: codex-review
description: |
  Codexを使った多角的コードレビュー。セキュリティ、パフォーマンス、保守性、設計の4観点で並列分析。
  Use for: "codexでレビュー", "多角的レビュー", "Codexに見てもらって", "別視点でレビュー"
allowed-tools: Bash, TaskOutput, Read
user-invocable: true
---

# Codex Multi-Perspective Review

4つの観点からcodex execを並列実行し、統合レポートを生成。

## Usage

```
/codex-review <target>
/codex-review src/auth/
/codex-review 最近の変更
```

## Execution

Bash toolで4つの`codex exec`を**並列バックグラウンド実行**:

```bash
# 4つ全てを run_in_background: true で並列起動
cd <target_dir> && codex exec "[Security Review] ..." --sandbox read-only 2>/dev/null
cd <target_dir> && codex exec "[Performance Review] ..." --sandbox read-only 2>/dev/null
cd <target_dir> && codex exec "[Maintainability Review] ..." --sandbox read-only 2>/dev/null
cd <target_dir> && codex exec "[Architecture Review] ..." --sandbox read-only 2>/dev/null
```

## Review Prompts

**Security:**
```
[Security Review] このプロジェクトを以下の観点でレビュー:
- 機密情報の露出リスク（APIキー、認証情報等）
- 入力検証の不備
- 安全でないデータ処理
具体的な問題箇所と修正案を提示。
```

**Performance:**
```
[Performance Review] このプロジェクトを以下の観点でレビュー:
- 不要なループ、毎フレーム処理の最適化機会
- メモリリーク、リソース解放漏れ
- GC Alloc削減の機会
- 計算量・アルゴリズム効率
具体的な問題箇所と改善案を提示。
```

**Maintainability:**
```
[Maintainability Review] このプロジェクトを以下の観点でレビュー:
- コードの可読性、複雑度
- 重複コード、DRY原則違反
- 命名規則、一貫性
- コメント・ドキュメントの適切さ
具体的な問題箇所とリファクタリング案を提示。
```

**Architecture:**
```
[Architecture Review] このプロジェクトを以下の観点でレビュー:
- 設計パターンの適切な使用
- 責務分離、単一責任原則
- 依存関係、結合度
- 拡張性、テスト容易性
具体的な問題箇所と改善案を提示。
```

## Workflow

1. 4つのBash toolを同時に起動
   - `run_in_background: true`
   - `timeout: 600000` (10分)
2. TaskOutputで全タスクの完了を待機
   - `timeout: 600000` (10分)
   - `block: true`
3. 結果を統合してレポート作成

## Output Format

```markdown
# Codex Multi-Perspective Review: <target>

## Summary
| 優先度 | 件数 |
|--------|------|
| Critical/High | X件 |
| Medium | X件 |
| Low | X件 |

## Security
[結果テーブル]

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

- 全て `--sandbox read-only` で実行（変更なし）
- `2>/dev/null` でstderr（進捗ログ）を抑制
- 結果の重複があれば統合時にマージ
