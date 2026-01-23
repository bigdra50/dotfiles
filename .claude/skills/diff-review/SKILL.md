---
name: diff-review
description: |
  git diffの結果をレビューしやすい形式で整形表示するスキル。
  変更ファイル一覧、各ファイルのdiff、変更量サマリーを構造化して出力。
  Use for: "diff見せて", "変更内容を確認", "レビューしやすく", "diffをまとめて", "/diff-review"
user-invocable: true
allowed-tools: Bash, Read
---

# Diff Review Skill

git diffの出力をレビューしやすい形式に整形する。

## Usage

```
/diff-review [options] [-- <path>...]
```

## Options

| Option | Description | git diff equivalent |
|--------|-------------|---------------------|
| (default) | 作業ツリーの変更（unstaged） | `git diff` |
| `staged` | ステージ済みの変更 | `git diff --staged` |
| `all` | staged + unstaged 両方 | `git diff HEAD` |
| `<commit>` | 特定コミットとの差分 | `git diff <commit>` |
| `<commit1>..<commit2>` | コミット間の差分 | `git diff <commit1>..<commit2>` |
| `-- <path>` | 特定ファイル/ディレクトリのみ | `git diff -- <path>` |

## Examples

```
/diff-review                    # unstaged changes
/diff-review staged             # staged changes only
/diff-review all                # all uncommitted changes
/diff-review HEAD~3             # last 3 commits
/diff-review main..feature      # branch comparison
/diff-review -- src/            # changes in src/ only
/diff-review staged -- *.cs     # staged C# files
```

## Output Format

以下の形式で出力する：

### 1. 変更ファイル一覧

```
変更ファイル一覧
================

[NEW]      path/to/new-file.cs
[EDIT]     path/to/modified-file.cs
[DELETE]   path/to/deleted-file.cs
[RENAME]   old-name.cs → new-name.cs
```

### 2. 変更量サマリー

```
## 変更量サマリー

| ファイル | 追加 | 削除 | 変更行計 |
|----------|------|------|----------|
| file1.cs | +25  | -10  | 35       |
| file2.cs | +5   | -0   | 5        |
| **合計** | +30  | -10  | 40       |
```

### 3. 各ファイルのdiff

各ファイルについて：

```
## path/to/file.cs [EDIT]

**目的**: （変更内容から推測して1行で説明）

```diff
- 削除された行
+ 追加された行
```

**主な変更点**:
- 変更点1
- 変更点2
```

## Implementation

1. オプションを解析してgit diffコマンドを構築
2. `git diff --stat` で変更量を取得
3. `git diff --name-status` で変更タイプを取得
4. `git diff` で詳細な差分を取得
5. 上記フォーマットで整形して出力

## Notes

- 大量の変更がある場合は、ファイル数を報告し、特定ファイルに絞るよう提案
- バイナリファイルは「[BINARY]」と表示
- 変更がない場合は「変更なし」と明示
