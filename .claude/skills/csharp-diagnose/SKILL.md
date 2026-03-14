---
name: csharp-diagnose
description: |
  C#コードの品質診断。ReSharper CLI (jb inspectcode) による静的解析と similarity-csharp による重複コード検出を組み合わせて改善点を報告する。プロジェクト種別（Unity/.NET等）を自動判定し、適切なオプションを選択する。
  Use for: "コード診断", "静的解析", "重複検出", "similarity", "inspectcode", "コード品質", "C#診断", "csharp diagnose"
---

# C# Code Diagnose

ReSharper CLI (`jb inspectcode`) と `similarity-csharp` で C# コードの品質と重複を診断する。

## Workflow

### 1. プロジェクト種別を判定

以下の手がかりからプロジェクト種別を判定する:

- Unity: `ProjectSettings/ProjectVersion.txt` が存在、または `.asmdef` ファイルが存在
- .NET: `.csproj` に `<Project Sdk="Microsoft.NET.Sdk">` 等

### 2. 対象とオプションを決定

ユーザー指示があればそれに従う。なければ CLAUDE.md の `jb` セクションや `--include` / `--exclude` パターンを参照する。CLAUDE.md にも記載がなければ以下のデフォルトを使う。

Unity プロジェクトの場合:
- `--no-build` 必須（標準 MSBuild でビルドできない）
- `-s=<solution>.sln.DotSettings` を付与（存在する場合。命名ルール等の設定反映に必要）
- `--exclude` でサードパーティを除外（`**/TextMesh Pro/**` 等）
- `Samples/` や Unity 内部パッケージの警告は無視

通常の .NET プロジェクトの場合:
- `--no-build` は任意（ビルド済みなら付与）
- `-s` は DotSettings が存在する場合のみ

### 3. 両ツールを並列実行

```bash
# 静的解析（SARIF出力）
jb inspectcode <solution>.sln \
  [--no-build] \
  [-s=<solution>.sln.DotSettings] \
  [--include="<pattern>"] \
  [--exclude="<pattern>"] \
  -e=WARNING \
  -o=results.sarif

# 重複検出
similarity-csharp -p <paths> --threshold 0.8 --min-lines 5
```

両コマンドは独立しているので並列実行する。

### 4. 結果を解析

静的解析:
```bash
jq '.runs[0].results | length' results.sarif
jq '.runs[0].results[] | {ruleId, message: .message.text, uri: .locations[0].physicalLocation.artifactLocation.uri, line: .locations[0].physicalLocation.region.startLine}' results.sarif
```

重複検出: コンソール出力をそのまま読み取る。

### 5. 統合レポート

以下の構成で報告する:

```
## 診断結果サマリー

| 項目 | 件数 |
|------|------|
| 静的解析 WARNING | N件 |
| 重複グループ | N件 |
| 重複行数 | N行 |

## 静的解析（ReSharper）
- 各警告をファイル:行番号付きで列挙

## 重複コード（similarity-csharp）
- 各グループの類似度・行数・該当メソッド名を列挙
- 共通化の提案（抽象化・ジェネリクス・委譲等）

## 改善提案
- 優先度順に具体的なリファクタリング方針を提示
```

### 6. クリーンアップ

`results.sarif` を削除する。

## オプション調整

詳細は [references/tool-options.md](references/tool-options.md) を参照。

よく使う調整:
- 閾値を緩めて広く検出: `--threshold 0.7`
- 大きなメソッドを除外: `--max-lines 100`
- 特定ディレクトリのみ: `-p src/Domain src/Application`
- ReSharper で INFO も含める: `-e=INFO`
