# create-mcp-tool

自然言語の要件からUnity Natural MCP用のカスタムMCPツールを自動生成します。

## ワークフロー:

1. **要件分析**
   - 自然言語からツールの目的と機能を抽出
   - メソッド名、パラメータ、戻り値の推定
   - Unity API使用の有無を判定

2. **設計確認**
   - ツール名とメソッド構成の提示
   - 非同期処理の必要性確認
   - エラーハンドリング要件の確認

3. **MCPツール生成**
   - `[McpServerToolType]`アトリビュート付きクラス作成
   - 各メソッドに`[McpServerTool]`アトリビュート適用
   - Description属性で詳細説明を追加

4. **Builder生成**
   - `McpBuilderScriptableObject`継承クラス作成
   - CreateAssetMenuアトリビュート設定
   - Build メソッドでツール登録実装

5. **ファイル配置とasmdef設定**
   - Editor用ディレクトリへの配置
   - asmdef の参照設定確認
   - ScriptableObject作成手順の説明

## 生成パターン:

### 基本的なMCPツール
```csharp
using System.ComponentModel;
using ModelContextProtocol.Server;

[McpServerToolType, Description("{ツールの説明}")]
public class {ToolName}MCPTool
{
    [McpServerTool, Description("{メソッドの説明}")]
    public string {MethodName}({Parameters})
    {
        // 実装
        return result;
    }
}
```

### Unity API使用ツール（非同期）
```csharp
using System.ComponentModel;
using ModelContextProtocol.Server;
using Cysharp.Threading.Tasks;
using UnityEngine;

[McpServerToolType, Description("{ツールの説明}")]
public class {ToolName}MCPTool
{
    [McpServerTool, Description("{メソッドの説明}")]
    public async ValueTask<string> {MethodName}({Parameters})
    {
        await UniTask.SwitchToMainThread();
        
        try
        {
            // Unity API操作
            var result = UnityOperation();
            return result;
        }
        catch (Exception e)
        {
            Debug.LogError($"Error in {MethodName}: {e.Message}");
            throw;
        }
    }
}
```

### Builderクラス
```csharp
using Microsoft.Extensions.DependencyInjection;
using UnityEngine;
using UnityNaturalMCP.Editor;

[CreateAssetMenu(fileName = "{ToolName}MCPToolBuilder",
                 menuName = "UnityNaturalMCP/{ToolName} Tool Builder")]
public class {ToolName}MCPToolBuilder : McpBuilderScriptableObject
{
    public override void Build(IMcpServerBuilder builder)
    {
        builder.WithTools<{ToolName}MCPTool>();
    }
}
```

## 自然言語解析ルール:

### ツール機能の推定
- "取得"、"get" → データ取得メソッド
- "設定"、"set" → データ設定メソッド
- "実行"、"run" → 処理実行メソッド
- "確認"、"check" → 状態確認メソッド
- "クリア"、"clear" → リセット処理

### Unity API判定キーワード
- GameObject、Transform、Component → Unity基本API
- AssetDatabase、EditorUtility → Editor API
- Debug、Console → ログ出力系
- Test、PlayMode、EditMode → テスト実行系

### 非同期処理判定
- 時間のかかる処理
- ファイルI/O操作
- ネットワーク通信
- Unity API呼び出し（メインスレッド必須）

## ベストプラクティス適用:

### エラーハンドリング
- try-catch でエラーをキャッチ
- Debug.LogError でログ出力
- 再スローで上位層に通知

### 非同期処理
- Unity API使用時は `UniTask.SwitchToMainThread()`
- 戻り値は `ValueTask<T>` を使用
- CancellationToken サポートの考慮

### パラメータ設計
- 複雑なパラメータは専用クラスで定義
- デフォルト値の適切な設定
- null チェックと検証

## 使用例:

### シンプルな要求
```bash
claude /create-mcp-tool "コンソールログを取得するツール"
claude /create-mcp-tool "アセットを更新するツール"
```

### 詳細な要求
```bash
claude /create-mcp-tool "指定したフィルターでログを検索して最新20件を返すツール"
claude /create-mcp-tool "Play Mode と Edit Mode のテストを実行できるツール"
```

### Unity固有機能
```bash
claude /create-mcp-tool "GameObjectの階層構造を取得するツール"
claude /create-mcp-tool "AssetDatabaseをリフレッシュするツール"
```

### 対話型モード
```bash
claude /create-mcp-tool
# ツール名、メソッド、パラメータなどを対話的に設定
```

## 生成後の手順:

1. **ファイル配置**
   - MCPツールクラス: `Assets/Editor/MCP/Tools/`
   - Builderクラス: `Assets/Editor/MCP/Builders/`

2. **ScriptableObject作成**
   - Project ウィンドウで右クリック
   - `Create > UnityNaturalMCP > {ToolName} Tool Builder` を選択

3. **MCPサーバー再起動**
   - `Edit > Project Settings > Unity Natural MCP > Refresh`
   - または Unity エディタ再起動

4. **動作確認**
   - MCP Inspector でツール呼び出し確認
   - Claude Code から実際に使用テスト

$ARGUMENTS が提供された場合は要件を解析してMCPツールを生成。引数なしの場合は対話型モードで詳細設定を収集します。