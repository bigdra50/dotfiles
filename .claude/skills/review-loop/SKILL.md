---
name: review-loop
description: |
  実装コードをCodexレビューで反復改善するループ。/codex-review実行→FB分類→コード修正→再レビューを収束まで繰り返す。
  Use for: "review-loop", "コード精度上げて", "レビューループ", "反復コードレビュー", "Codexと品質上げる"
user-invocable: true
---

# Code Review Loop

実装済みコードに /codex-review を実行し、指摘を反映して再レビューする反復ループ。

## When NOT to use

- 単発レビューで十分なとき → `/codex-review` (loop なし)
- 設計プランのレビュー対象 → `/plan-loop`
- Copilot CLI を使いたい → `/copilot-review-loop`
- メトリクス駆動の構造改善 → `/refactor-loop`
- まだコードを書いていない → 通常会話で実装してから

## Pitfalls (read first)

| Symptom | Cause | Fix |
|---|---|---|
| 同じ指摘が毎ラウンド出る | 修正履歴が次ラウンドの reviewer に渡っていない | 各ラウンドの修正内容を要約し、次の `/codex-review` 引数に含める |
| 修正がテストを壊す | Step 4 のテスト実行をスキップしている | プロジェクトの test command を CLAUDE.md から特定し必ず実行 |
| `--staged` で対象が空 | git add していない / staging が古い | `git status` で確認、必要なら `git add` を促す |
| MUST が永遠にゼロにならない | 修正対象の判断ミスで別ファイルを直している | reviewer が指摘した `file:line` を厳格に追う |
| ラウンドが 1 回で収束する | reviewer が浅いレビューしかしていない | `/codex-review` の 4 観点 prompt が省略されていないか確認 |

## Usage

```
/review-loop                    # 直近の変更を対象にループ開始
/review-loop src/relay/         # 指定パスを対象
/review-loop --staged           # git staged の変更を対象
```

## Workflow

```python
target = resolve_target(args or recent_changes)
round = 0
history = []

while True:
    round += 1
    review = codex_review(target)            # /codex-review を実行
    must, should, nice = classify(review)
    report_to_user(round, must, should, nice)

    if not must and not should:
        break
    if user_wants_to_stop():
        break

    approved = ask_user_which_to_address(must + should)
    apply_fixes(target, approved)            # コードを修正
    run_tests_if_available()                 # テスト実行で壊れていないか確認
    history.append((review, approved))

print_summary(history)
```

## Step 1: 対象特定

レビュー対象を決定する:

- 引数にパスがあればそのパス
- `--staged` なら `git diff --staged` の変更ファイル
- なければ会話コンテキストから直近の変更ファイルを特定
- それでもなければユーザーに確認

## Step 2: /codex-review 実行

Skill tool で `/codex-review` を実行する。対象パスを引数として渡す。

4観点（セキュリティ、パフォーマンス、保守性、設計）の並列レビュー結果が返る。

## Step 3: FB 分類

レビュー結果の各指摘を重大度で再分類:

- [MUST] バグ、セキュリティ脆弱性、データ損失リスク
- [SHOULD] パフォーマンス改善、設計改善、可読性向上
- [NICE] スタイル、命名の好み、ドキュメント追加

```
Round N レビュー結果:
  MUST:   X件 — {一覧}
  SHOULD: X件 — {一覧}
  NICE:   X件 — {一覧}
```

ユーザーに報告し、対応方針を確認する。

## Step 4: コード修正

ユーザーの承認を得た MUST + SHOULD 項目に対してコードを修正する。

修正後、テストがあれば実行して既存の動作を壊していないか確認する。
テスト実行コマンドはプロジェクトの CLAUDE.md や設定から判断する。

## Step 5: 収束判定

以下のいずれかで終了:
- MUST と SHOULD が両方 0 件
- ユーザーが終了を指示

ラウンド数の上限は設けない。収束するまで繰り返す。

終了時、全ラウンドのサマリーを報告:

```
## Code Review Summary

| Round | MUST | SHOULD | NICE | 修正ファイル数 |
|-------|------|--------|------|----------------|
| 1     | 2    | 4      | 3    | 5              |
| 2     | 1    | 2      | 1    | 3              |
| 3     | 0    | 0      | 1    | 0              |

対応済み: X件 / 未対応 (NICE): X件
```

## Anti-patterns

| 合理化 | 実像 |
|---|---|
| 「テスト失敗したけどレビュー結果は反映済みだから次へ」 | 修正で別の不具合を導入。テスト緑化前に次ラウンドへ進まない |
| 「NICE は無視してよい (時間ない)」 | NICE が積もると debt 化。ユーザーに判断を委ねる方が良い |
| 「`--staged` ならテスト不要 (commit 前なので)」 | staged の状態で壊れていれば commit してから困る。テストは必ず |
| 「Codex が同じ指摘繰り返すから収束した」 | 指摘の伝達がうまくいっていないだけ。修正履歴を要約して渡す |
| 「reviewer の出力をそのまま applied=true にしてよい」 | reviewer は提案するだけ。承認はユーザー、適用は別ステップ |

## Related skills

- `/plan-loop` — 設計プランを Codex でループ (code ではなく plan 対象)
- `/copilot-review-loop` — 同じワークフローを Copilot CLI で実施
- `/refactor-loop` — メトリクス駆動の構造改善ループ (CodeHealth 系、別系統)
- `/codex-review` — このスキルが委譲する単発 4 観点レビュー
- `/dual-review` — Claude + Codex/Copilot を統合した単発レビュー
- `empirical-prompt-tuning` (mizchi) — このスキル自体の品質を bias-free に評価

## Notes

- レビューは `/codex-review` スキルに委譲する。直接 codex exec を呼ばない
- 各ラウンドの修正内容を次ラウンドのレビューに反映し、同じ指摘の繰り返しを防ぐ
- コード修正はユーザー承認後に実行する。自動修正はしない
- NICE 項目は対応を強制しない。ユーザー判断に委ねる
