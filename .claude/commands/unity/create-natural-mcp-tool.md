# Create Natural MCP Tool

## Custom MCP Tool Implementation

### 1. Create MCP Tool

UnityNaturalMCPでは、[MCP C# SDK](https://github.com/modelcontextprotocol/csharp-sdk)を用いて、C#でMCPツールを実装することができます。

Editor用のasmdefを作成し、次のスクリプトファイルを追加します。

```csharp
using System.ComponentModel;
using ModelContextProtocol.Server;

[McpServerToolType, Description("カスタムMCPツールの説明")]
public class MyCustomMCPTool
{
    [McpServerTool, Description("メソッドの説明")]
    public string MyMethod()
    {
        return "Hello from Unity!";
    }
}
```

### 2. Create MCP Tool Builder

MCPツールをMCPサーバーに登録するためには、`McpBuilderScriptableObject`を継承したクラスを作成します。

```csharp
using Microsoft.Extensions.DependencyInjection;
using UnityEngine;
using UnityNaturalMCP.Editor;

[CreateAssetMenu(fileName = "MyCustomMCPToolBuilder",
                 menuName = "UnityNaturalMCP/My Custom Tool Builder")]
public class MyCustomMCPToolBuilder : McpBuilderScriptableObject
{
    public override void Build(IMcpServerBuilder builder)
    {
        builder.WithTools<MyCustomMCPTool>();
    }
}
```

### 3. Create ScriptableObject

1. Unity Editorでプロジェクトウィンドウを右クリック
2. `Create > UnityNaturalMCP > My Custom Tool Builder` を選択してScriptableObjectを作成
3. `Edit > Project Settings > Unity Natural MCP > Refresh` から、MCPサーバーを再起動すると、作成したツールが読み込まれます。

### Best practices for Custom MCP Tools

#### MCPInspector

[MCP Inspector](https://github.com/modelcontextprotocol/inspector)から、Streamable HTTPを介してMCPツールを呼び出し、動作確認をスムーズに行うことができます。

![MCPInspector](docs/images/mcp_inspector.png)

#### Error Handling

MCPツール内でエラーが発生した場合、それはログに表示されません。

try-catchブロックを使用して、エラーをログに記録し、再スローすることを推奨します。

```csharp
[McpServerTool, Description("エラーを返す処理の例")]
public async void ErrorMethod()
{
  try
  {
      throw new Exception("This is an error example");
  }
  catch (Exception e)
  {
      Debug.LogError(e);
      throw;
  }
}
```

#### Asynchonous Processing

UnityのAPIを利用する際は、メインスレッド以外から呼び出される可能性を考慮する必要があります。

また、戻り値の型には、 `ValueTask<T>` を利用する必要があります。

```csharp
[McpServerTool, Description("非同期処理の例")]
public async ValueTask<string> AsyncMethod()
{
    await UniTask.SwitchToMainThread();
    await UniTask.Delay(1000);
    return "非同期処理完了";
}
```
