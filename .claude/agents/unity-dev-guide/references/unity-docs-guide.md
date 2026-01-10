# Unity Documentation Guide

Unity公式ドキュメント体系と効率的な検索方法のリファレンス。

## Documentation Structure

### 公式ドキュメントサイト

| サイト | 用途 | URL |
|--------|------|-----|
| Manual | 概念説明、ワークフロー | docs.unity3d.com/{ver}/Documentation/Manual/ |
| ScriptReference | API仕様 | docs.unity3d.com/{ver}/Documentation/ScriptReference/ |
| Package Docs | パッケージAPI | docs.unity3d.com/Packages/{package}@{ver}/ |
| Learn | チュートリアル | learn.unity.com |
| Forum | コミュニティQ&A | forum.unity.com |

### バージョン表記

| Unity Version | URL表記 |
|---------------|---------|
| Unity 6 | 6000.0 |
| Unity 2023 LTS | 2023.2 |
| Unity 2022 LTS | 2022.3 |

## Search Patterns

### API検索

```
# クラス全体
site:docs.unity3d.com ScriptReference {ClassName}

# 特定メソッド
site:docs.unity3d.com {ClassName}.{MethodName}

# プロパティ
site:docs.unity3d.com {ClassName}-{propertyName}
```

### トピック検索

```
# 機能説明
site:docs.unity3d.com Manual {topic}

# ベストプラクティス
site:docs.unity3d.com {topic} best practices

# パフォーマンス
site:docs.unity3d.com {topic} performance optimization
```

### トラブルシューティング

```
# エラー解決
site:forum.unity.com {error message}

# 既知の問題
site:issuetracker.unity3d.com {issue}
```

## UnityCsReference MCP

### 概要

UnityのC#ソースコード参照用MCP。
URL: `https://gitmcp.io/Unity-Technologies/UnityCsReference`

### 活用パターン

1. **内部実装確認**: ドキュメントに詳細がない場合
2. **エッジケース調査**: 特殊な動作の理由を理解
3. **拡張ポイント特定**: カスタマイズ可能な箇所を発見

### 検索例

```
# MonoBehaviour ライフサイクル
Runtime/Export/Scripting/MonoBehaviour.bindings.cs

# Editor拡張
Editor/Mono/Inspector/

# シリアライズ
Runtime/Serialization/
```

## Package Documentation

### UPMパッケージ

ローカルキャッシュの参照順序:

1. `Library/PackageCache/{package}/README.md`
2. `Library/PackageCache/{package}/Documentation~/`
3. `Library/PackageCache/{package}/package.json` → documentationUrl

### 主要パッケージドキュメント

| パッケージ | ドキュメントURL |
|-----------|-----------------|
| com.unity.ugui | docs.unity3d.com/Packages/com.unity.ugui@latest |
| com.unity.textmeshpro | docs.unity3d.com/Packages/com.unity.textmeshpro@latest |
| com.unity.inputsystem | docs.unity3d.com/Packages/com.unity.inputsystem@latest |
| com.unity.addressables | docs.unity3d.com/Packages/com.unity.addressables@latest |
| com.unity.entities | docs.unity3d.com/Packages/com.unity.entities@latest |

## YAML File Reference

### ファイル形式ドキュメント

| トピック | URL |
|---------|-----|
| アセットメタデータ | docs.unity3d.com/Manual/AssetMetadata.html |
| シリアライズ形式 | docs.unity3d.com/Manual/FormatDescription.html |
| UnityYAML概要 | docs.unity3d.com/Manual/UnityYAML.html |
| YAML詳細仕様 | docs.unity3d.com/Manual/YAMLFileFormat.html |
| ClassID一覧 | docs.unity3d.com/Manual/ClassIDReference.html |

### 主要ClassID

| ClassID | Type |
|---------|------|
| 1 | GameObject |
| 4 | Transform |
| 23 | MeshRenderer |
| 33 | MeshFilter |
| 114 | MonoBehaviour |
| 115 | MonoScript |

## Performance Topics

### 検索キーワード

- Profiler使用法: `Unity Profiler tutorial`
- メモリ最適化: `Unity memory optimization GC`
- 描画最適化: `Unity draw call batching`
- ビルドサイズ: `Unity build size reduction`
- ロード時間: `Unity loading time optimization`

### 公式リソース

- Performance Best Practices: `docs.unity3d.com/Manual/BestPracticeGuides.html`
- Profiler: `docs.unity3d.com/Manual/Profiler.html`
- Memory Profiler: `docs.unity3d.com/Packages/com.unity.memoryprofiler@latest`
