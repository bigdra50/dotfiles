#!/bin/bash

# Claude Code タスク完了通知
# Stopイベントで発火し、作業完了をユーザーに通知
# CLAUDE.mdの基本方針に従い、sayコマンドでユーザーを音声で呼び出し

# エンコーディングを設定
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

# 音声読み上げ設定
SPEECH_RATE_EN=160
SPEECH_RATE_JA=180

# 基本情報を取得
current_dir=$(pwd)
project_name=$(basename "$current_dir")
current_time=$(date '+%H:%M:%S')

# stdinからhook JSONを読み取り
hook_json=$(cat)
transcript_path=""
session_id=""
last_user_content=""
last_assistant_content=""

# hook JSONから情報を抽出
if [ -n "$hook_json" ]; then
    transcript_path=$(echo "$hook_json" | jq -r '.transcript_path // empty' 2>/dev/null)
    session_id=$(echo "$hook_json" | jq -r '.session_id // empty' 2>/dev/null)
    
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
        echo "DEBUG: session_id=$session_id" >> ~/.claude-task-complete.log
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

# 音声メッセージを構築と読み上げ
if command -v say >/dev/null 2>&1; then
    # 1. 完了メッセージ
    completion_message="Task completed. Project: ${project_name}"
    say -r "$SPEECH_RATE_EN" "$completion_message"
    
    # 2. ユーザーの問いかけを読み上げ
    if [ -n "$last_user_content" ] && [ "$last_user_content" != "null" ]; then
        # ユーザーメッセージが長い場合は先頭140文字に切り詰める
        truncated_user_content=$(echo "$last_user_content" | head -c 140)
        if [ ${#last_user_content} -gt 140 ]; then
            truncated_user_content="${truncated_user_content}..."
        fi
        user_audio_message="質問: ${truncated_user_content}"
        say -v Kyoko -r "$SPEECH_RATE_JA" "$user_audio_message"
    fi
    
    # 3. エージェントの回答を読み上げ
    if [ -n "$last_assistant_content" ] && [ "$last_assistant_content" != "null" ]; then
        # アシスタントメッセージが長い場合は先頭280文字に切り詰める
        truncated_assistant_content=$(echo "$last_assistant_content" | head -c 280)
        if [ ${#last_assistant_content} -gt 280 ]; then
            truncated_assistant_content="${truncated_assistant_content}..."
        fi
        assistant_audio_message="回答: ${truncated_assistant_content}"
        say -v Kyoko -r "$SPEECH_RATE_JA" "$assistant_audio_message"
    fi
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
