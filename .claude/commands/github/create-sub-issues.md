---
description: |
  親Issueに対して複数のSub-issuesを一括作成し紐付ける。
  Usage: /create-sub-issues <parent_issue_number>
  ARGUMENTSにタスクリストを含める。チェックリスト形式も解析可能。
  Use for: "サブタスク一括作成", "チェックリストをIssue化", "タスク分解"
allowed-tools:
  - Bash
  - Read
---

# Create Sub-issues (Batch)

親Issueに複数のSub-issuesを一括作成して紐付ける。

## 引数解析

ARGUMENTSから以下を抽出:
- `parent_number`: 親Issue番号（必須）
- タスクリスト: 以下の形式を解析
  - `- [ ] タスク名` (チェックリスト形式)
  - `- タスク名` (箇条書き形式)
  - `1. タスク名` (番号付きリスト形式)

## 実行手順

### 1. リポジトリ情報取得

```bash
gh repo view --json owner,name
```

### 2. 親IssueのNode ID取得

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      id
      title
    }
  }
}' -f owner="$OWNER" -f repo="$REPO" -F number=$PARENT_NUMBER
```

### 3. 各Sub-issue作成 & 紐付け

タスクリストの各項目に対して:

```bash
# Issue作成
ISSUE_URL=$(gh issue create --title "$TITLE" --body "$BODY")
ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')

# Node ID取得
SUB_ID=$(gh api graphql -f query='...' -F number=$ISSUE_NUM --jq '.data.repository.issue.id')

# 親に紐付け
gh api graphql \
  -H "GraphQL-Features: sub_issues" \
  -f query='
  mutation($parentId: ID!, $subIssueId: ID!) {
    addSubIssue(input: {issueId: $parentId, subIssueId: $subIssueId}) {
      subIssue { number title url }
    }
  }' \
  -f parentId="$PARENT_ID" \
  -f subIssueId="$SUB_ID"
```

## 出力形式

```
親Issue: #<number> <title>
├── #<num1> <title1> ✓
├── #<num2> <title2> ✓
└── #<num3> <title3> ✓

作成完了: <n>件のSub-issues
```

## 使用例

```
/create-sub-issues 590
- [ ] God Objectの責務分析
- [ ] IMGUIHelperの分割
- [ ] テストカバレッジ向上
```
