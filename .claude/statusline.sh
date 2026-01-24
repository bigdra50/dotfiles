#!/bin/bash
# Context-aware Status Line with NerdFont devicons
# Displays: Model | Directory | Git Status | Project Type | Time
# StatusLine JSON Input Structure (see https://docs.claude.com/en/docs/claude-code/statusline)
# {
#  "hook_event_name": "Status",
#  "session_id": "abc123...",
#  "transcript_path": "/path/to/transcript.json",
#  "cwd": "/current/working/directory",
#  "model": {
#    "id": "claude-opus-4-1",
#    "display_name": "Opus"
#  },
#  "workspace": {
#    "current_dir": "/current/working/directory",
#    "project_dir": "/original/project/directory"
#  },
#  "version": "1.0.80",
#  "output_style": {
#    "name": "default"
#  },
#  "cost": {
#    "total_cost_usd": 0.01234,
#    "total_duration_ms": 45000,
#    "total_api_duration_ms": 2300,
#    "total_lines_added": 156,
#    "total_lines_removed": 23
#  }
#}

# Read JSON input from stdin
input=$(cat)

# ============================================================================
# Extract Basic Information
# ============================================================================

MODEL_ID=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // "~"')
TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // ""')

# Extract time information
TOTAL_DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
DURATION_MIN=$((TOTAL_DURATION_MS / 60000))
DURATION_SEC=$(((TOTAL_DURATION_MS % 60000) / 1000))

# Calculate relative directory
if [[ "$CURRENT_DIR" == "$PROJECT_DIR"* ]]; then
    REL_DIR="${CURRENT_DIR#$PROJECT_DIR}"
    REL_DIR="${REL_DIR#/}"
    DISPLAY_DIR="${REL_DIR:-$(basename "$PROJECT_DIR")}"
else
    DISPLAY_DIR=$(basename "$CURRENT_DIR")
fi

# ============================================================================
# Color Definitions (Monokai Theme - TrueColor RGB)
# ============================================================================

# TrueColor RGB - Monokai Palette
# Format: \033[38;2;R;G;Bm (24-bit color)
# Using $'...' syntax to interpret escape sequences at assignment time
C_RESET=$'\033[0m'
C_GRAY=$'\033[38;2;117;113;94m'       # #75715E
C_RED=$'\033[38;2;249;38;114m'        # #F92672
C_RED_BRIGHT=$'\033[38;2;249;38;114m' # #F92672
C_GREEN=$'\033[38;2;166;226;46m'      # #A6E22E
C_GREEN_BRIGHT=$'\033[38;2;166;226;46m' # #A6E22E
C_YELLOW=$'\033[38;2;230;219;116m'    # #E6DB74
C_YELLOW_BRIGHT=$'\033[38;2;230;219;116m' # #E6DB74
C_BLUE=$'\033[38;2;102;217;239m'      # #66D9EF
C_BLUE_BRIGHT=$'\033[38;2;102;217;239m' # #66D9EF
C_MAGENTA=$'\033[38;2;174;129;255m'   # #AE81FF
C_CYAN=$'\033[38;2;161;239;228m'      # #A1EFE4
C_CYAN_BRIGHT=$'\033[38;2;161;239;228m' # #A1EFE4
C_ORANGE=$'\033[38;2;253;151;31m'     # #FD971F
C_WHITE=$'\033[38;2;248;248;242m'     # #F8F8F2

# ============================================================================
# Model Icon & Display
# ============================================================================

# Determine robot icon and color based on Claude's state
get_robot_icon_and_color() {
    local transcript="$TRANSCRIPT_PATH"

    # Icons using UTF-8 byte sequences
    local icon_default=$(echo "󰚩")
    local icon_happy=$(echo "󱜙")
    local icon_confused=$(echo "󱚟")
    # local icon_excited=$(echo "󱚣")   # Not used - similar to happy
    local icon_dead=$(echo "󱚡")         # Reserved for future error detection
    local icon_angry=$(echo "󱚝")        # Reserved for future critical warnings

    # Default values (cyan for working state)
    local icon="$icon_default"
    local color="$C_BLUE"

    # If no transcript, use default
    if [[ ! -f "$transcript" ]]; then
        echo "${icon}|${color}"
        return
    fi

    # Check if thinking block exists in last message
    local is_thinking=$(~/.claude/tools/check-last-thinking.sh "$transcript" 2>/dev/null)

    # If thinking, use confused icon regardless of stop_reason
    if [[ "$is_thinking" == "thinking" ]]; then
        icon="$icon_confused"
        color="$C_YELLOW"
    else
        # Get stop_reason from last assistant message
        local stop_reason=$(~/.claude/tools/get-last-stop-reason.sh "$transcript" 2>/dev/null)

        # Determine icon and color based on stop_reason
        case "$stop_reason" in
            "end_turn"|"null")
                # Normal completion - Happy with success color
                icon="$icon_happy"
                color="$C_GREEN"
                ;;
            "max_tokens")
                # Token limit reached - Confused with warning color
                icon="$icon_confused"
                color="$C_YELLOW"
                ;;
            "tool_use")
                # Tool usage - Default with working color
                icon="$icon_default"
                color="$C_BLUE"
                ;;
            "stop_sequence"|*)
                # Custom stop or unknown - Default with working color
                icon="$icon_default"
                color="$C_BLUE"
                ;;
        esac
    fi

    echo "${icon}|${color}"
}

# Get robot icon and color based on stop_reason
ICON_AND_COLOR=$(get_robot_icon_and_color)
MODEL_ICON="${ICON_AND_COLOR%|*}"
ICON_COLOR="${ICON_AND_COLOR#*|}"

# Build model display with dynamic icon color
case "$MODEL_ID" in
    *[Ss]onnet*)
        MODEL_DISPLAY="${ICON_COLOR}${MODEL_ICON} ${C_BLUE}${MODEL_ID}${C_RESET}"
        ;;
    *[Oo]pus*)
        MODEL_DISPLAY="${ICON_COLOR}${MODEL_ICON} ${C_MAGENTA}${MODEL_ID}${C_RESET}"
        ;;
    *[Hh]aiku*)
        MODEL_DISPLAY="${ICON_COLOR}${MODEL_ICON} ${C_GREEN_BRIGHT}${MODEL_ID}${C_RESET}"
        ;;
    *)
        MODEL_DISPLAY="${ICON_COLOR}${MODEL_ICON} ${C_WHITE}${MODEL_ID}${C_RESET}"
        ;;
esac

# ============================================================================
# Project Type Detection with NerdFont devicons
# ============================================================================

detect_project_type() {
    local search_dir="$PROJECT_DIR"

    # Unity Project (highest priority)
    if [[ -d "$search_dir/Assets" ]] && [[ -d "$search_dir/ProjectSettings" ]]; then
        # Use nf-dev-unity icon for all Unity versions (U+E721)
        echo -e "\xEE\x9C\xA1"  # nf-dev-unity (U+E721)
        return
    fi

    # Check for package.json (Node.js/React/Vue/etc.)
    if [[ -f "$search_dir/package.json" ]]; then
        local pkg_content=$(cat "$search_dir/package.json" 2>/dev/null)

        # React
        if echo "$pkg_content" | grep -q '"react"'; then
            echo -e "\xEE\x9E\xBA"  # nf-dev-react (U+E7BA)
            return
        fi

        # Vue
        if echo "$pkg_content" | grep -q '"vue"'; then
            echo -e "\xEF\xB5\x82"  # nf-dev-vue (U+FD42)
            return
        fi

        # Next.js
        if echo "$pkg_content" | grep -q '"next"'; then
            echo -e "\xF3\xB0\xB8\x81"  # nf-md-nextjs (U+F0E01)
            return
        fi

        # TypeScript
        if [[ -f "$search_dir/tsconfig.json" ]]; then
            echo -e "\xEE\x98\xA8"  # nf-dev-typescript (U+E628)
            return
        fi

        # Default Node.js
        echo -e "\xEE\x9C\x99"  # nf-dev-nodejs (U+E719)
        return
    fi

    # Rust
    if [[ -f "$search_dir/Cargo.toml" ]]; then
        echo -e "\xEE\x9E\xA8"  # nf-dev-rust (U+E7A8)
        return
    fi

    # Go
    if [[ -f "$search_dir/go.mod" ]]; then
        echo -e "\xEE\x9C\xA4"  # nf-seti-go (U+E724)
        return
    fi

    # Python
    if [[ -f "$search_dir/pyproject.toml" ]] || [[ -f "$search_dir/setup.py" ]] || [[ -f "$search_dir/requirements.txt" ]]; then
        echo -e "\xF3\xB0\x8C\xA0"  # nf-md-language_python (U+F0320)
        return
    fi

    # .NET/C# (excluding Unity which is checked first)
    if ls "$search_dir"/*.csproj &>/dev/null || ls "$search_dir"/*.sln &>/dev/null; then
        echo -e "\xF3\xB0\xAA\xAE"  # nf-md-language_csharp (U+F0AAE)
        return
    fi

    # Ruby
    if [[ -f "$search_dir/Gemfile" ]]; then
        echo -e "\xF3\xB0\xB4\xAD"  # nf-md-language_ruby (U+F0D2D)
        return
    fi

    # Java (Maven)
    if [[ -f "$search_dir/pom.xml" ]]; then
        echo -e "\xEE\x9C\xB8"  # nf-dev-java (U+E738)
        return
    fi

    # Java/Kotlin (Gradle)
    if [[ -f "$search_dir/build.gradle" ]] || [[ -f "$search_dir/build.gradle.kts" ]]; then
        echo -e "\xF3\xB1\x83\xBE"  # nf-md-language_kotlin (U+F10FE)
        return
    fi

    # PHP
    if [[ -f "$search_dir/composer.json" ]]; then
        echo -e "\xF3\xB0\x8C\x9F"  # nf-md-language_php (U+F031F)
        return
    fi

    # Swift
    if [[ -f "$search_dir/Package.swift" ]]; then
        echo -e "\xEE\x9D\x95"  # nf-dev-swift (U+E755)
        return
    fi

    # No project type detected - return empty string
    echo ""
}

PROJECT_ICON=$(detect_project_type)

# ============================================================================
# Project Version Detection
# ============================================================================

detect_project_version() {
    local search_dir="$PROJECT_DIR"

    # Unity
    if [[ -d "$search_dir/Assets" ]] && [[ -d "$search_dir/ProjectSettings" ]]; then
        local version_file="$search_dir/ProjectSettings/ProjectVersion.txt"
        if [[ -f "$version_file" ]]; then
            grep 'm_EditorVersion:' "$version_file" 2>/dev/null | sed 's/m_EditorVersion: *//' | head -1
        fi
        return
    fi

    # Node.js/React/Vue/Next.js/TypeScript
    if [[ -f "$search_dir/package.json" ]]; then
        local pkg_content=$(cat "$search_dir/package.json" 2>/dev/null)

        # React version
        if echo "$pkg_content" | grep -q '"react"'; then
            echo "$pkg_content" | jq -r '.dependencies.react // .devDependencies.react // empty' 2>/dev/null | sed 's/[\^~]//g'
            return
        fi

        # Vue version
        if echo "$pkg_content" | grep -q '"vue"'; then
            echo "$pkg_content" | jq -r '.dependencies.vue // .devDependencies.vue // empty' 2>/dev/null | sed 's/[\^~]//g'
            return
        fi

        # Next.js version
        if echo "$pkg_content" | grep -q '"next"'; then
            echo "$pkg_content" | jq -r '.dependencies.next // .devDependencies.next // empty' 2>/dev/null | sed 's/[\^~]//g'
            return
        fi

        # TypeScript version
        if [[ -f "$search_dir/tsconfig.json" ]]; then
            echo "$pkg_content" | jq -r '.dependencies.typescript // .devDependencies.typescript // empty' 2>/dev/null | sed 's/[\^~]//g'
            return
        fi

        # Node.js version from engines
        echo "$pkg_content" | jq -r '.engines.node // empty' 2>/dev/null | sed 's/[\^~>=]//g'
        return
    fi

    # Rust
    if [[ -f "$search_dir/Cargo.toml" ]]; then
        grep '^version' "$search_dir/Cargo.toml" 2>/dev/null | head -1 | sed 's/^version *= *"\([^"]*\)".*/\1/'
        return
    fi

    # Go
    if [[ -f "$search_dir/go.mod" ]]; then
        grep '^go ' "$search_dir/go.mod" 2>/dev/null | head -1 | awk '{print $2}'
        return
    fi

    # Python
    if [[ -f "$search_dir/pyproject.toml" ]]; then
        grep 'python' "$search_dir/pyproject.toml" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)".*/\1/' | sed 's/[\^~>=]//g'
        return
    elif [[ -f "$search_dir/.python-version" ]]; then
        cat "$search_dir/.python-version" 2>/dev/null
        return
    fi

    # .NET/C#
    if ls "$search_dir"/*.csproj &>/dev/null; then
        local csproj=$(ls "$search_dir"/*.csproj 2>/dev/null | head -1)
        grep '<TargetFramework>' "$csproj" 2>/dev/null | head -1 | sed 's/.*<TargetFramework>\([^<]*\)<\/TargetFramework>.*/\1/'
        return
    fi

    # Ruby
    if [[ -f "$search_dir/.ruby-version" ]]; then
        cat "$search_dir/.ruby-version" 2>/dev/null
        return
    elif [[ -f "$search_dir/Gemfile.lock" ]]; then
        grep -A 1 "RUBY VERSION" "$search_dir/Gemfile.lock" 2>/dev/null | tail -1 | tr -d ' '
        return
    fi

    # Java (Maven)
    if [[ -f "$search_dir/pom.xml" ]]; then
        grep '<java.version>' "$search_dir/pom.xml" 2>/dev/null | head -1 | sed 's/.*<java.version>\([^<]*\)<\/java.version>.*/\1/'
        return
    fi

    # PHP
    if [[ -f "$search_dir/composer.json" ]]; then
        jq -r '.require.php // empty' "$search_dir/composer.json" 2>/dev/null | sed 's/[\^~>=]//g'
        return
    fi

    echo ""
}

PROJECT_VERSION=$(detect_project_version)

# ============================================================================
# Git Status Detection
# ============================================================================

get_git_status() {
    # Disable optional locks to prevent .git/index.lock issues in statusline
    export GIT_OPTIONAL_LOCKS=0

    # Check if in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        return
    fi

    local branch=""
    local git_icons=""

    # Get current branch
    branch=$(git branch --show-current 2>/dev/null)
    if [[ -z "$branch" ]]; then
        # Detached HEAD
        branch="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
        branch="$(echo -e "\xF3\xB0\xB8\xAC") ${branch}"  # nf-md-source_commit (U+F0E2C)
    else
        # Normal branch - add branch icon
        branch="$(echo -e "\xEE\x82\xA0") ${branch}"  # nf-oct-git_branch (U+E0A0)
    fi

    # Check for merge/rebase
    local git_dir=$(git rev-parse --git-dir 2>/dev/null)
    if [[ -f "$git_dir/MERGE_HEAD" ]]; then
        git_icons="${git_icons}⚡"  # Merge in progress
    elif [[ -d "$git_dir/rebase-merge" ]] || [[ -d "$git_dir/rebase-apply" ]]; then
        git_icons="${git_icons}⟳"  # Rebase in progress
    fi

    # Get working tree status
    local status_output=$(git status --porcelain 2>/dev/null)

    if [[ -n "$status_output" ]]; then
        # Check for staged changes
        if echo "$status_output" | grep -q "^[MADRCU]"; then
            git_icons="${git_icons}●"  # Staged changes
        fi

        # Check for modified files
        if echo "$status_output" | grep -q "^ M"; then
            git_icons="${git_icons}✎"  # Modified
        fi

        # Check for untracked files
        if echo "$status_output" | grep -q "^??"; then
            git_icons="${git_icons}?"  # Untracked
        fi
    else
        git_icons="${git_icons}✓"  # Clean
    fi

    # Check ahead/behind remote
    local upstream=$(git rev-parse --abbrev-ref @{u} 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        local ahead_behind=$(git rev-list --left-right --count HEAD...$upstream 2>/dev/null)
        local ahead=$(echo "$ahead_behind" | awk '{print $1}')
        local behind=$(echo "$ahead_behind" | awk '{print $2}')

        if [[ "$ahead" -gt 0 ]]; then
            git_icons="${git_icons}↑${ahead}"
        fi
        if [[ "$behind" -gt 0 ]]; then
            git_icons="${git_icons}↓${behind}"
        fi
    fi

    # Color based on status
    local git_color="$C_GREEN_BRIGHT"
    if echo "$git_icons" | grep -q "[⚡⟳]"; then
        git_color="$C_RED_BRIGHT"  # Merge/Rebase
    elif echo "$git_icons" | grep -q "[●✎?]"; then
        git_color="$C_YELLOW_BRIGHT"  # Changes present
    fi

    echo "${git_color} ${branch} ${git_icons}${C_RESET}"
}

GIT_STATUS=$(get_git_status)

# ============================================================================
# Memory Status Detection
# ============================================================================

get_memory_status() {
    # Get total memory in bytes
    local total_bytes=$(sysctl -n hw.memsize 2>/dev/null)

    # Get memory pressure info which includes free percentage
    local mem_pressure=$(memory_pressure 2>/dev/null)
    local free_percent=$(echo "$mem_pressure" | grep "System-wide memory free percentage:" | awk '{print $5}' | tr -d '%')

    # Validate inputs
    if [[ -z "$total_bytes" ]] || [[ -z "$free_percent" ]]; then
        echo ""
        return
    fi

    # Calculate used memory
    local used_percent=$((100 - free_percent))
    local used_bytes=$((total_bytes * used_percent / 100))

    # Convert to GB (round to nearest integer)
    local total_gb=$((total_bytes / 1024 / 1024 / 1024))
    local used_gb=$((used_bytes / 1024 / 1024 / 1024))

    # Determine color based on usage percentage
    local mem_color="$C_GREEN"
    if [[ $used_percent -gt 80 ]]; then
        mem_color="$C_RED"
    elif [[ $used_percent -gt 60 ]]; then
        mem_color="$C_YELLOW"
    fi

    # Memory icon using UTF-8 byte sequence (nf-md-memory U+F035B)
    local mem_icon=$(echo -e "\xF3\xB0\x8D\x9B")

    echo "${C_MAGENTA}${mem_icon} ${mem_color}${used_gb}/${total_gb}GB${C_RESET}"
}

MEMORY_STATUS=$(get_memory_status)

# ============================================================================
# Build Status Line
# ============================================================================

# Components
STATUS_LINE=""

# 1. Model
STATUS_LINE="${STATUS_LINE}${MODEL_DISPLAY}"

# 2. Directory (use devicon - git-aware)
# Choose icon based on whether directory is under git control
if GIT_OPTIONAL_LOCKS=0 git rev-parse --git-dir > /dev/null 2>&1; then
    # Under git control - use git folder icon
    DIR_ICON="$(echo -e "")"  # nf-oct-file_submodule (U+F0256)
else
    # Not under git control - use regular folder icon
    DIR_ICON="$(echo -e "")"  # nf-oct-file_directory (U+F0116)
fi
STATUS_LINE="${STATUS_LINE} ${C_GREEN}${DIR_ICON} ${DISPLAY_DIR}${C_RESET}"

# 3. Memory Status
if [[ -n "$MEMORY_STATUS" ]]; then
    STATUS_LINE="${STATUS_LINE} ${MEMORY_STATUS}"
fi

# 4. Time (current time and session duration)
CURRENT_TIME=$(date +"%H:%M")
TIME_ICON="$(echo -e "\xF3\xB0\xA5\x94")"  # nf-md-clock (U+F0954)

if [[ $DURATION_MIN -gt 0 ]]; then
    STATUS_LINE="${STATUS_LINE} ${C_ORANGE}${TIME_ICON} ${CURRENT_TIME} (${DURATION_MIN}m)${C_RESET}"
elif [[ $DURATION_SEC -gt 0 ]]; then
    STATUS_LINE="${STATUS_LINE} ${C_ORANGE}${TIME_ICON} ${CURRENT_TIME} (${DURATION_SEC}s)${C_RESET}"
else
    STATUS_LINE="${STATUS_LINE} ${C_ORANGE}${TIME_ICON} ${CURRENT_TIME}${C_RESET}"
fi

# 5. Project Type
if [[ -n "$PROJECT_ICON" ]]; then
    if [[ -n "$PROJECT_VERSION" ]]; then
        STATUS_LINE="${STATUS_LINE} ${C_WHITE}${PROJECT_ICON} ${PROJECT_VERSION}${C_RESET}"
    else
        STATUS_LINE="${STATUS_LINE} ${C_WHITE}${PROJECT_ICON}${C_RESET}"
    fi
fi

# 6. Git Status
if [[ -n "$GIT_STATUS" ]]; then
    STATUS_LINE="${STATUS_LINE}${GIT_STATUS}"
fi

# ============================================================================
# Output
# ============================================================================

echo "$STATUS_LINE"
