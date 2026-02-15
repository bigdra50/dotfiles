#!/usr/bin/env bash
set -euo pipefail

# PreCompact hook: 会話履歴をMarkdownに変換して保存
# stdin: {"transcript_path": "...", "cwd": "...", "session_id": "..."}

HISTORY_REPO="github.com/upfrontier/claude-code-history"
GHQ_ROOT="$(ghq root 2>/dev/null || echo "$HOME/dev")"
DEST_BASE="${GHQ_ROOT}/${HISTORY_REPO}"

# stdin から JSON を読み取り
input="$(cat)"
transcript_path="$(echo "$input" | jq -r '.transcript_path // empty')"
cwd="$(echo "$input" | jq -r '.cwd // empty')"
session_id="$(echo "$input" | jq -r '.session_id // empty')"

# transcript_path が取得できなければ終了
if [[ -z "$transcript_path" ]]; then
  exit 0
fi

# ~ を展開
transcript_path="${transcript_path/#\~/$HOME}"

# JSONL ファイルが存在しなければ終了
if [[ ! -f "$transcript_path" ]]; then
  exit 0
fi

# cwd から git リポジトリ情報を取得
repo_path=""
branch=""
if [[ -n "$cwd" && -d "$cwd" ]]; then
  remote_url="$(git -C "$cwd" remote get-url origin 2>/dev/null || true)"
  branch="$(git -C "$cwd" branch --show-current 2>/dev/null || true)"

  if [[ -n "$remote_url" ]]; then
    # SSH形式: git@github.com:user/repo.git → github.com/user/repo
    # HTTPS形式: https://github.com/user/repo.git → github.com/user/repo
    repo_path="$(echo "$remote_url" | sed -E 's#^(https?://|git@)##; s#:#/#; s#\.git$##')"
  fi
fi

# 保存先ディレクトリ決定
if [[ -n "$repo_path" ]]; then
  dest_dir="${DEST_BASE}/${repo_path}"
else
  dest_dir="${DEST_BASE}/other"
fi

mkdir -p "$dest_dir"

# ファイル名: YYYY-MM-DDTHH-MM-<session_id先頭8桁>.md
timestamp="$(date '+%Y-%m-%dT%H-%M')"
short_id="${session_id:0:8}"
filename="${timestamp}-${short_id}.md"
dest_file="${dest_dir}/${filename}"

# 既に同一ファイルがあればスキップ
if [[ -f "$dest_file" ]]; then
  exit 0
fi

# リポジトリ名（表示用）
display_repo="${repo_path:-"(リポジトリ外)"}"
display_date="$(date '+%Y-%m-%d %H:%M')"

# Markdown ヘッダー生成
{
  echo "# 会話ログ (auto-saved)"
  echo ""
  echo "- 日時: ${display_date}"
  echo "- リポジトリ: ${display_repo}"
  echo "- ブランチ: ${branch:-"(不明)"}"
  echo "- セッションID: ${session_id}"
  echo ""
  echo "## 会話履歴"
} > "$dest_file"

# JSONL を解析して会話を抽出
# --slurp で配列化し、連続するassistantメッセージを統合
jq -r --slurp '
  # 各行を {role, text} に変換
  [.[] |
    if .type == "user" and (.isMeta | not) then
      if (.message.content | type) == "string" then
        if (.message.content | test("<command-name>|<local-command-stdout>")) then
          empty
        else
          {role: "user", text: .message.content}
        end
      elif (.message.content | type) == "array" then
        (.message.content | map(
          if .type == "text" then .text else empty end
        ) | join("\n")) as $t |
        if ($t | length) > 0 then {role: "user", text: $t} else empty end
      else empty end
    elif .type == "assistant" then
      (.message.content | map(
        if .type == "text" and .text != "(no content)" then .text
        elif .type == "tool_use" then "[Tool: " + .name + "]"
        else empty end
      ) | join("\n")) as $t |
      if ($t | length) > 0 then {role: "assistant", text: $t} else empty end
    else empty end
  ] |
  # 連続する同一roleを統合
  reduce .[] as $item ([];
    if (length > 0) and (.[-1].role == $item.role) then
      .[-1].text += ("\n" + $item.text)
    else
      . + [$item]
    end
  ) |
  # Markdown出力
  .[] |
  if .role == "user" then
    "\n### 🧑 User\n\n" + .text
  else
    "\n### 🤖 Assistant\n\n" + .text
  end
' "$transcript_path" >> "$dest_file"
