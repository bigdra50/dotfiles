#!/bin/bash

# Unity C# ファイル編集後の自動検証スクリプト
# PostToolUse hook で Edit|MultiEdit|Write 後に実行
#
# 処理フロー:
#   1. .cs ファイルの編集かどうかをチェック
#   2. Unity MCP サーバーへのヘルスチェック
#   3. Assets/Refresh 実行
#   4. 短い待機 (コンパイル開始を待つ)
#   5. コンソールログ取得 (error のみ)

# --- 設定 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_CLIENT="$CLAUDE_PROJECT_DIR/tools/unity-mcp-client/unity_mcp_client.py"
MCP_HOST="localhost"
MCP_PORT="6400"
SLEEP_SECONDS=2
LOG_TYPES="error"
LOG_COUNT=20

# --- stdin から hook JSON を読み取り ---
hook_json=$(cat)

# tool_input から file_path を抽出
file_path=$(echo "$hook_json" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

# .cs ファイル以外は何もしない
if [[ ! "$file_path" =~ \.cs$ ]]; then
    exit 0
fi

# --- ヘルスチェック: TCP ポート疎通確認 ---
if ! nc -z "$MCP_HOST" "$MCP_PORT" 2>/dev/null; then
    echo "⚠️ Unity MCP server not available at $MCP_HOST:$MCP_PORT" >&2
    echo "   Please ensure Unity Editor is open with MCP bridge running" >&2
    exit 0  # 非ブロッキング終了（警告のみ）
fi

# --- MCP クライアントの存在確認 ---
if [[ ! -f "$MCP_CLIENT" ]]; then
    echo "⚠️ Unity MCP client not found: $MCP_CLIENT" >&2
    exit 0
fi

# --- 実行 ---
echo "🔄 Unity: Refreshing assets after C# edit..."
echo "   File: $file_path"

# 1. Assets/Refresh 実行
python3 "$MCP_CLIENT" --host "$MCP_HOST" --port "$MCP_PORT" refresh 2>/dev/null

# 2. コンパイル開始を待つ
sleep "$SLEEP_SECONDS"

# 3. コンソールログ取得
result=$(python3 "$MCP_CLIENT" --host "$MCP_HOST" --port "$MCP_PORT" console --types $LOG_TYPES --count "$LOG_COUNT" 2>/dev/null)

# 4. エラーがあれば表示
error_count=$(echo "$result" | jq '.data | length' 2>/dev/null || echo "0")

if [[ "$error_count" -gt 0 && "$error_count" != "null" ]]; then
    echo ""
    echo "❌ Unity Console Errors ($error_count):"
    echo "$result" | jq -r '.data[] | "  [\(.type)] \(.message)"' 2>/dev/null
    # exit 2 でブロッキングエラーにする場合はコメントを外す
    # exit 2
else
    echo "✅ Unity: No compilation errors detected"
fi

exit 0
