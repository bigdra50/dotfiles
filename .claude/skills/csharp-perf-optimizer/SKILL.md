---
name: csharp-perf-optimizer
description: >
  C#コードベースのパフォーマンス最適化提案。Cysharp/neuecc OSSの知見に基づき、
  ゼロアロケーション、Span活用、Source Generator移行、SIMD化、struct設計、
  バッファ管理、async最適化、UTF-8ネイティブ処理、データレイアウト改善など
  12カテゴリで分析・提案する。
  Use for: C#最適化, パフォーマンス改善, アロケーション削減, C# perf, 高速化,
  .NET最適化, GC圧力, ゼロアロケーション, Span化, Source Generator移行
---

# C# Performance Optimizer

Cysharp/neuecc OSS (ZLinq, MemoryPack, UniTask等) から体系化した12カテゴリの最適化パターンでC#コードを分析し、改善提案を行う。

## Workflow

### 1. Scan: プロジェクト情報の収集

Determine target framework and C# version:

```bash
# .csproj から TargetFramework と LangVersion を取得
grep -r "TargetFramework\|LangVersion" --include="*.csproj"
```

Identify hot paths and high-impact files:
- Grep for patterns listed in [references/optimization-patterns.md](references/optimization-patterns.md)
- Prioritize: inner loops, serialization, I/O, frequently called methods

### 2. Analyze: パターンマッチング

Read [references/optimization-patterns.md](references/optimization-patterns.md) and match against the codebase. Each category has grep patterns for detection.

Priority order (impact high → low):
1. **Allocation** — `string.Format`, `ToArray()`, `new MemoryStream`, LINQ on hot path
2. **Span/Memory** — `Substring`, `Encoding.GetBytes`, `Array.Copy`, temp buffers
3. **Async** — `async Task<T>` on hot path, sync-over-async (`Result`, `Wait()`)
4. **Buffer** — `MemoryStream`, repeated `new byte[]`, no pooling
5. **Struct** — small class as value holder, class enumerator
6. **Source Generator** — reflection, `typeof()`, `GetProperties()`, IL.Emit
7. **UTF-8** — `Encoding.UTF8.GetString/GetBytes` in I/O pipeline
8. **SIMD** — numeric array loops (Sum, Min, Max, Contains)
9. **Serialization** — `BinaryFormatter`, `Newtonsoft` on hot path
10. **Data Layout** — struct array with field-only bulk operations
11. **Native Memory** — very large arrays (>85KB LOH threshold)
12. **Language Features** — outdated patterns replaceable by modern C#

### 3. Report: 提案レポート

Format findings as:

```
## [Category] Finding Title

Impact: High / Medium / Low
File: path/to/file.cs:line

### Current
(problematic code snippet)

### Proposed
(optimized code snippet)

### Rationale
(1-2 sentences explaining the optimization)
```

Group by impact level (High → Medium → Low).

### 4. Constraints

- Target framework に応じた提案のみ行う (.NET 6 なら ref field (C# 11) は提案しない)
- Unity プロジェクトでは UniTask, ZString 等の Unity 対応ライブラリを優先提案
- 破壊的変更を伴う提案は明示する
- 可読性を著しく損なう提案は避ける（過度な Unsafe 使用等）
