---
description: |
  親Issueに対してSub-issueを作成し紐付ける。
  Usage: /create-sub-issue <parent_issue_number> <title> [body]
  Use for: "sub-issue作成", "子Issue追加", "タスク分割", "サブタスク追加"
allowed-tools:
  - Bash
---

# Create Sub-issue

親IssueにSub-issueを作成して紐付ける。

## 引数解析

ARGUMENTSから以下を抽出:
- `parent_number`: 親Issue番号（必須）
- `title`: Sub-issueのタイトル（必須）
- `body`: Sub-issueの本文（オプション、なければタイトルから生成）

## 実行手順

### 1. Sub-issue作成

```bash
gh issue create \
  --title "<title>" \
  --body "<body>"
```

### 2. 親IssueのNode ID取得

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      id
    }
  }
}' -f owner="<owner>" -f repo="<repo>" -F number=<parent_number>
```

### 3. Sub-issueのNode ID取得

作成したIssue番号で同様にNode IDを取得。

### 4. Sub-issueを親に紐付け

```bash
gh api graphql \
  -H "GraphQL-Features: sub_issues" \
  -f query='
  mutation($parentId: ID!, $subIssueId: ID!) {
    addSubIssue(input: {issueId: $parentId, subIssueId: $subIssueId}) {
      issue { title }
      subIssue { title number url }
    }
  }' \
  -f parentId="<parent_id>" \
  -f subIssueId="<sub_issue_id>"
```

## 出力

作成されたSub-issueのURL と 親Issueへの紐付け結果を表示。

## エラーハンドリング

- 親Issueが存在しない場合: エラーメッセージを表示
- GraphQL APIエラー: ヘッダー確認を促す
