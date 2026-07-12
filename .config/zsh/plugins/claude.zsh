# Claude Code ログ検索システム
claude-search() {
    local log_dir="$HOME/.claude/projects"
    
    if [ ! -d "$log_dir" ]; then
        echo "Claude Code ログディレクトリが見つかりません: $log_dir"
        return 1
    fi
    
    echo "🔍 Claude Code セッション検索"
    echo "プロジェクト数: $(ls -1d $log_dir/*/ 2>/dev/null | wc -l)"
    
    # JSONL形式の会話ログをインタラクティブ検索
    rg --line-number --color=always --type-add 'jsonl:*.jsonl' --type jsonl . "$log_dir" | \
    fzf --ansi \
        --delimiter ':' \
        --preview 'claude-preview {1} {2}' \
        --preview-window 'right:60%:+{2}/2' \
        --bind 'enter:execute(nvim +{2} {1})' \
        --bind 'change:reload(rg --line-number --color=always --type-add "jsonl:*.jsonl" --type jsonl {q} '"$log_dir"' || true)' \
        --bind 'ctrl-h:execute(open $(dirname {1})/session-$(basename {1} .jsonl).html)' \
        --header 'Type to search | Enter: nvim | Ctrl-H: open HTML'
}

# Claude Code プロジェクト選択
claude-project() {
    local log_dir="$HOME/.claude/projects"
    
    if [ ! -d "$log_dir" ]; then
        echo "Claude Code ログディレクトリが見つかりません: $log_dir"
        return 1
    fi
    
    # プロジェクト選択（デコードされた名前で表示）
    local project=$(ls -1d $log_dir/*/ | sed "s|$log_dir/||g" | sed 's|/$||g' | \
        fzf --preview 'claude-project-info {}' \
            --header 'Select Claude Code project')
    
    if [ -n "$project" ]; then
        echo "📂 選択されたプロジェクト: $project"
        claude-search-in-project "$project"
    fi
}

# 特定プロジェクト内での検索
claude-search-in-project() {
    local project="$1"
    local log_dir="$HOME/.claude/projects"
    local project_path="$log_dir/$project"
    
    rg --line-number --color=always --type-add 'jsonl:*.jsonl' --type jsonl . "$project_path" | \
    fzf --ansi \
        --delimiter ':' \
        --preview 'claude-preview {1} {2}' \
        --bind 'enter:execute(nvim +{2} {1})' \
        --bind 'ctrl-h:execute(open $(dirname {1})/session-$(basename {1} .jsonl).html)' \
        --header "Project: $project | Enter: nvim | Ctrl-H: HTML"
}

# JSONメッセージ内容の検索（ユーザー/アシスタント別）
claude-search-by-role() {
    local role=${1:-"user"}  # user, assistant, system
    local log_dir="$HOME/.claude/projects"
    
    echo "🎭 検索対象: ${role}メッセージ"
    
    rg --line-number --color=always --type-add 'jsonl:*.jsonl' --type jsonl \
       "\"role\":\"$role\"" "$log_dir" | \
    fzf --ansi \
        --delimiter ':' \
        --preview 'claude-message-preview {1} {2}' \
        --header "Role: $role messages"
}

# セッション別検索
claude-search-session() {
    local log_dir="$HOME/.claude/projects"
    
    # セッションIDで検索
    if [ -n "$1" ]; then
        rg --line-number --color=always --type-add 'jsonl:*.jsonl' --type jsonl \
           "\"sessionId\":\"$1\"" "$log_dir"
    else
        # インタラクティブセッション選択
        rg --color=always --type-add 'jsonl:*.jsonl' --type jsonl \
           '"sessionId"' "$log_dir" | \
        grep -o '"sessionId":"[^"]*"' | \
        sort -u | \
        sed 's/"sessionId":"//g' | sed 's/"//g' | \
        fzf --preview 'claude-session-summary {}' \
            --header 'Select session ID'
    fi
}

# 日付範囲検索
claude-search-date() {
    local date=${1:-$(date +%Y-%m-%d)}
    local log_dir="$HOME/.claude/projects"
    
    echo "📅 検索日付: $date"
    
    rg --line-number --color=always --type-add 'jsonl:*.jsonl' --type jsonl \
       "\"timestamp\":\"$date" "$log_dir" | \
    fzf --ansi \
        --delimiter ':' \
        --preview 'claude-preview {1} {2}' \
        --header "Date: $date"
}

# エラー・警告検索
claude-search-errors() {
    local log_dir="$HOME/.claude/projects"
    
    echo "🚨 エラー・例外・警告を検索中..."
    
    rg --line-number --color=always --type-add 'jsonl:*.jsonl' --type jsonl \
       -i "error|exception|warning|failed|traceback" "$log_dir" | \
    fzf --ansi \
        --delimiter ':' \
        --preview 'claude-preview {1} {2}' \
        --header 'Error/Warning/Exception search'
}

# コマンド実行履歴検索
claude-search-commands() {
    local log_dir="$HOME/.claude/projects"
    
    echo "⚡ 実行されたコマンドを検索中..."
    
    rg --line-number --color=always --type-add 'jsonl:*.jsonl' --type jsonl \
       '"type":".*command|execute|run' "$log_dir" | \
    fzf --ansi \
        --delimiter ':' \
        --preview 'claude-preview {1} {2}' \
        --header 'Command execution history'
}

# プレビュー関数（JSON整形表示）
claude-preview() {
    local file="$1"
    local line="$2"
    
    if command -v jq >/dev/null 2>&1; then
        # jqが利用可能な場合、JSONを整形表示
        sed -n "${line}p" "$file" | jq '.'
    else
        # jqが利用できない場合、batで表示
        bat --color=always --language=json --highlight-line "$line" "$file"
    fi
}

# メッセージ内容のプレビュー
claude-message-preview() {
    local file="$1"
    local line="$2"
    
    if command -v jq >/dev/null 2>&1; then
        local json_line=$(sed -n "${line}p" "$file")
        echo "$json_line" | jq -r '.message.content' | head -20
        echo "---"
        echo "Role: $(echo "$json_line" | jq -r '.message.role')"
        echo "Timestamp: $(echo "$json_line" | jq -r '.timestamp')"
        echo "Session: $(echo "$json_line" | jq -r '.sessionId')"
    else
        sed -n "${line}p" "$file"
    fi
}

# プロジェクト情報表示
claude-project-info() {
    local project="$1"
    local log_dir="$HOME/.claude/projects"
    local project_path="$log_dir/$project"
    
    echo "📁 プロジェクト: $project"
    echo "📄 セッション数: $(ls -1 "$project_path"/*.jsonl 2>/dev/null | wc -l)"
    echo "📅 最終更新: $(ls -lt "$project_path"/*.jsonl 2>/dev/null | head -1 | awk '{print $6, $7, $8}')"
    echo ""
    echo "📋 最近のセッション:"
    ls -1t "$project_path"/*.jsonl 2>/dev/null | head -5 | while read file; do
        local session_id=$(basename "$file" .jsonl)
        echo "  • $session_id"
    done
}

# セッション要約表示
claude-session-summary() {
    local session_id="$1"
    local log_dir="$HOME/.claude/projects"
    
    echo "🔍 セッション: $session_id"
    
    # セッションIDを含むファイルを検索
    local files=$(rg -l "\"sessionId\":\"$session_id\"" "$log_dir" --type-add 'jsonl:*.jsonl' --type jsonl)
    
    if [ -n "$files" ]; then
        echo "$files" | while read file; do
            echo "📁 $(dirname "$file" | sed "s|$log_dir/||")"
            if command -v jq >/dev/null 2>&1; then
                local message_count=$(rg "\"sessionId\":\"$session_id\"" "$file" | wc -l)
                echo "💬 メッセージ数: $message_count"
                
                # 最初と最後のメッセージの時間を取得
                local first_time=$(rg "\"sessionId\":\"$session_id\"" "$file" | head -1 | jq -r '.timestamp' 2>/dev/null)
                local last_time=$(rg "\"sessionId\":\"$session_id\"" "$file" | tail -1 | jq -r '.timestamp' 2>/dev/null)
                echo "⏰ 期間: $first_time ～ $last_time"
            fi
        done
    fi
}

# エイリアス設定
alias cls='claude-search'           # 全体検索
alias clp='claude-project'          # プロジェクト選択
alias clr='claude-search-by-role'   # ロール別検索
alias cld='claude-search-date'      # 日付検索
alias cle='claude-search-errors'    # エラー検索
alias clc='claude-search-commands'  # コマンド検索
alias css='claude-search-session'   # セッション検索

# ─── claude -p プロファイル ───────────────────────────────────
#
# cc           : デフォルト（セッション設定のモデル）
# cc-opus      : 複雑な設計・レビュー向け
# cc-sonnet    : 日常の実装タスク
# cc-haiku     : 軽量な質問・変換
# cc-fable     : 創造的タスク
#
# 使い方:
#   cc "このコードをレビューして"
#   echo "data" | cc "要約して"
#   cc-sonnet --output-format json "APIのスキーマを生成"
#   cc-select "対話的にモデル選択"

cc() {
    claude -p "$@"
}

cc-opus() {
    claude -p --model claude-opus-4-8 "$@"
}

cc-sonnet() {
    claude -p --model claude-sonnet-5 "$@"
}

cc-haiku() {
    claude -p --model claude-haiku-4-5-20251001 "$@"
}

cc-fable() {
    claude -p --model claude-fable-5 "$@"
}

cc-select() {
    local models=(
        "claude-opus-4-8:Opus 4.8 — 最高精度、設計・レビュー"
        "claude-sonnet-5:Sonnet 5 — バランス型、日常タスク"
        "claude-haiku-4-5-20251001:Haiku 4.5 — 高速・軽量"
        "claude-fable-5:Fable 5 — 創造的タスク"
    )
    local selected
    selected=$(printf '%s\n' "${models[@]}" | \
        fzf --delimiter ':' \
            --with-nth 2 \
            --header 'モデルを選択 (ESC でキャンセル)' \
            --preview 'echo "Model ID: {1}"' \
            --height '~10') || return 0
    local model_id="${selected%%:*}"
    echo "Using: $model_id"
    claude -p --model "$model_id" "$@"
}

cc-local() {
    if ! command -v ollama &>/dev/null; then
        echo "ollama が見つかりません。インストールしてください。" >&2
        return 1
    fi
    local model="${CC_LOCAL_MODEL:-hermes3:14b}"
    echo "Local: $model (ollama)" >&2
    ollama run "$model" "$@"
}
