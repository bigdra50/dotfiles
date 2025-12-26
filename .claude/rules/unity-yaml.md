---
paths: "**/*.{meta,asset,prefab,unity}"
---

# Editing the Unity YAML file

## 推奨ワークフロー

生YAMLを直接読むとコンテキストを大量消費する。まずCLIで構造化情報を取得すること。

### 1. CLIでコンテキスト取得（優先）

```bash
# シーン構造を取得
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp scene hierarchy

# アクティブシーン情報
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp scene active

# 特定GameObjectを検索
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp gameobject find <name>

# マテリアル情報
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp material info --path <path>
```

### 2. CLIで操作（可能な場合）

```bash
# GameObject操作
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp gameobject create --name "Name" --primitive Cube
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp gameobject modify --name "Name" --position 0,1,0

# シーン操作
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp scene save
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp scene load --name SceneName

# マテリアル操作
uvx --from git+https://github.com/bigdra50/unity-mcp-client unity-mcp material set-color --path Assets/Mat.mat --color 1,0,0,1
```

### 3. 直接編集（CLIで不可能な場合のみ）

CLIで対応できない操作のみ、ファイルを直接編集する。
編集前に以下のドキュメントを参照すること。

## リファレンス

### .meta file

- https://docs.unity3d.com/Manual/AssetMetadata.html

### .asset, .prefab, .unity file

- https://docs.unity3d.com/Manual/FormatDescription.html
- https://docs.unity3d.com/Manual/UnityYAML.html
- https://docs.unity3d.com/Manual/YAMLFileFormat.html
- https://docs.unity3d.com/Manual/ClassIDReference.html
