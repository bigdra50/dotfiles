#!/bin/bash

# Claude Code タスク完了通知
# Stopイベントで発火し、作業完了をユーザーに通知
# CLAUDE.mdの基本方針に従い、sayコマンドでユーザーを音声で呼び出し

# エンコーディングを設定
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

# 基本情報を取得
current_dir=$(pwd)
project_name=$(basename "$current_dir")
current_time=$(date '+%H:%M:%S')

# 最新のdebug JSONファイルからtranscript_pathを取得
latest_debug_json=$(ls -t ~/bin/.stop-event-debug-*.json 2>/dev/null | head -1)
last_user_content=""
last_assistant_content=""

if [ -n "$latest_debug_json" ] && [ -f "$latest_debug_json" ]; then
    transcript_path=$(jq -r '.transcript_path' "$latest_debug_json" 2>/dev/null)
    
    if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
        # 最後のuser messageのcontentを抽出（文字列のみ、スラッシュコマンド対応）
        last_user_content=$(jq -r 'select(.type == "user" and .message.role == "user" and (.message.content | type) == "string") | 
            if (.message.content | test("<command-name>")) then
                .message.content | capture("<command-name>(?<cmd>[^<]+)</command-name>") | .cmd
            else
                .message.content
            end' "$transcript_path" 2>/dev/null | tail -1)
        
        # 最後のassistant messageのcontentを抽出（textタイプのみ）
        last_assistant_content=$(jq -r 'select(.type == "assistant" and .message.role == "assistant") | .message.content[]? | select(.type == "text") | .text' "$transcript_path" 2>/dev/null | tail -1)
        
        # デバッグ情報をログに出力
        echo "DEBUG: transcript_path=$transcript_path" >> ~/.claude-task-complete.log
        echo "DEBUG: last_user_content=$last_user_content" >> ~/.claude-task-complete.log
        echo "DEBUG: last_assistant_content=$last_assistant_content" >> ~/.claude-task-complete.log
    fi
fi

# Gitリポジトリの場合、ブランチ名を取得
if [ -d .git ]; then
    branch=$(git branch --show-current 2>/dev/null || echo "main")
    git_info=" (${branch})"
else
    git_info=""
fi

# 通知メッセージを構築
if [ -n "$last_user_content" ] && [ "$last_user_content" != "null" ]; then
    # ユーザーメッセージが長い場合は先頭100文字に切り詰める
    truncated_user_content=$(echo "$last_user_content" | head -c 100)
    if [ ${#last_user_content} -gt 100 ]; then
        truncated_user_content="${truncated_user_content}..."
    fi
    title="✅ $truncated_user_content"
else
    title="Claude Code ✅ タスク完了"
fi

message=""

# 最後のアシスタントメッセージを最初に表示
if [ -n "$last_assistant_content" ] && [ "$last_assistant_content" != "null" ]; then
    message="🤖 ${last_assistant_content}"
fi

# 最後のユーザーメッセージを次に表示
if [ -n "$last_user_content" ] && [ "$last_user_content" != "null" ]; then
    if [ -n "$message" ]; then
        message="${message}

👤 ${last_user_content}"
    else
        message="👤 ${last_user_content}"
    fi
fi

# プロジェクト情報を最後に表示
if [ -n "$message" ]; then
    message="${message}

---
プロジェクト: ${project_name}${git_info}
完了時刻: ${current_time}
場所: ${current_dir}"
else
    message="プロジェクト: ${project_name}${git_info}
完了時刻: ${current_time}
場所: ${current_dir}"
fi

# 音声メッセージを構築（escaped_titleを使用）
if [ -n "$last_user_content" ] && [ "$last_user_content" != "null" ]; then
    # ユーザーメッセージが長い場合は先頭50文字に切り詰める
    truncated_for_audio=$(echo "$last_user_content" | head -c 50)
    if [ ${#last_user_content} -gt 50 ]; then
        truncated_for_audio="${truncated_for_audio}..."
    fi
    audio_message="完了しました。${truncated_for_audio}"
else
    audio_message="タスクが完了しました。プロジェクト: ${project_name}"
fi

# 1. 音声通知（CLAUDE.mdの基本方針に従う）
if command -v say >/dev/null 2>&1; then
    say -v Kyoko "$audio_message"
fi

# 2. WezTerm通知（bell）
printf '\a'

# 3. macOS通知
if command -v osascript >/dev/null 2>&1; then
    # 特殊文字をエスケープして通知
    escaped_title=$(printf '%s' "$title" | sed 's/\\/\\\\/g; s/"/\\"/g')
    escaped_message=$(printf '%s' "$message" | sed 's/\\/\\\\/g; s/"/\\"/g')
    osascript -e "display notification \"${escaped_message}\" with title \"${escaped_title}\" sound name \"Glass\"" 2>/dev/null
fi

# 4. ログ出力
echo "$(date '+%Y-%m-%d %H:%M:%S') - [TASK_COMPLETE] ${project_name} in ${current_dir}" >> ~/.claude-task-complete.log