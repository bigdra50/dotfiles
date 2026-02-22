---
name: plan-loop
description: |
  設計プランをCodexレビューで反復改善するループ。プラン作成→Codexレビュー→FB反映→再レビューを収束まで繰り返す。
  Use for: "plan-loop", "プラン精度上げて", "Codexとプラン練る", "設計レビューループ", "反復レビュー"
user-invocable: true
---

# Plan Review Loop

設計プランをCodex agentにレビュー依頼し、フィードバックを反映して再レビューする反復ループ。

## Usage

```
/plan-loop                  # 会話中のプランを対象にループ開始
/plan-loop path/to/plan.md  # 指定ファイルを対象
```

## Workflow

```python
plan = resolve_plan(args or conversation_context)
files = extract_related_files(plan)
round = 0
history = []

while True:
    round += 1
    review = codex_review(plan, files, history)
    must, should, nice = classify(review)
    report_to_user(round, must, should, nice)

    if not must and not should:
        break
    if user_wants_to_stop():
        break

    approved = ask_user_which_to_address(must + should)
    apply_feedback(plan, approved)
    history.append((review, approved))

print_summary(history)
```

## Step 1: プラン準備

プランファイルを特定する。引数があればそのパスを使用。なければ会話コンテキストから直近のプランファイルパスを探す。

プランが存在しない場合はユーザーに確認してから作成を支援する。

## Step 2: Codex レビュー依頼

Task tool で codex agent を起動。プロンプトに含める内容:

1. プランファイルのパス（Codexに読ませる）
2. レビュー対象の関連ソースファイル一覧
3. レビュー観点の指定
4. 前回のレビュー結果と対応内容（2回目以降）

レビュープロンプトのテンプレート:

### 初回

```
以下の設計プランをレビューしてください。

## プランファイル
{plan_path} を読んでください。

## 関連ソースファイル
{file_list}

## レビュー観点
1. 設計: アーキテクチャの適切さ、責務分離
2. パフォーマンス: ホットパス、メモリ、計算量
3. スレッド安全性 / 並行性
4. 後方互換性: 既存の動作を壊さないか
5. テスト戦略: カバレッジの十分さ
6. エッジケース: 見落としている境界条件

## 出力形式
指摘を重大度で分類:
- [MUST] 対応しないとバグ・障害に直結
- [SHOULD] 対応すると品質が上がる
- [NICE] あると良いが必須ではない

日本語で回答してください。
```

### 2回目以降

```
前回の指摘への対応を反映したプランを再レビューしてください。

## プランファイル
{plan_path} を読んでください。

## 前回の指摘と対応状況
{previous_feedback_and_responses}

## レビュー依頼
1. 前回の指摘が適切に解消されているか確認
2. 対応により新たに生じた問題がないか確認
3. 残存する懸念点があれば指摘

同じ出力形式 ([MUST] / [SHOULD] / [NICE]) で回答してください。
日本語で回答してください。
```

## Step 3: FB 分類

Codex の回答から指摘を抽出し、重大度別に整理:

```
Round N レビュー結果:
  MUST:   X件 — {一覧}
  SHOULD: X件 — {一覧}
  NICE:   X件 — {一覧}
```

ユーザーに結果を報告し、対応方針を確認する。

## Step 4: プランに反映

ユーザーの承認を得た MUST + SHOULD 項目をプランに反映する。
各指摘に対して、プランのどの箇所をどう変更したかを追跡する。

## Step 5: 収束判定

以下のいずれかで終了:
- MUST と SHOULD が両方 0 件
- ユーザーが終了を指示

ラウンド数の上限は設けない。収束するまで繰り返す。

終了時、全ラウンドのレビュー結果サマリーを報告:

```
## Plan Review Summary

| Round | MUST | SHOULD | NICE |
|-------|------|--------|------|
| 1     | 3    | 5      | 2    |
| 2     | 2    | 3      | 1    |
| 3     | 0    | 1      | 0    |
| 4     | 0    | 0      | 0    |

対応済み: X件 / 未対応 (NICE): X件
```

## Notes

- Codex agent は `subagent_type: codex` で起動する
- プランの関連ファイル一覧は会話コンテキストまたはプラン内のファイルパスから自動抽出する
- 各ラウンドの Codex レビュー結果は次ラウンドのプロンプトに含め、同じ指摘の繰り返しを防ぐ
- NICE 項目は対応を強制しない。ユーザー判断に委ねる
