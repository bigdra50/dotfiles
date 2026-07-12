#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib.sh"

RULES_DIR="$HOME/.claude/rules"
CODEX_HEADER="$DOTFILES_DIR/.codex/AGENTS.header.md"
COPILOT_HEADER="$DOTFILES_DIR/.copilot/instructions.header.md"
CODEX_OUT="$HOME/.codex/AGENTS.md"
COPILOT_OUT="$HOME/.copilot/copilot-instructions.md"

# --- Frontmatter parser ---

parse_rule_file() {
    local file="$1"
    local in_fm=false
    local fm_done=false
    local patterns=""
    local sync="true"
    local in_array=false
    RULE_PATTERNS=""
    RULE_BODY=""
    RULE_SYNC="true"

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$fm_done" == "false" ]]; then
            if [[ "$line" == "---" ]]; then
                if [[ "$in_fm" == "true" ]]; then
                    fm_done=true
                    in_fm=false
                else
                    in_fm=true
                fi
                continue
            fi
            if [[ "$in_fm" == "true" ]]; then
                if [[ "$line" =~ ^(paths|globs):\ *\"(.+)\"$ ]]; then
                    patterns="${BASH_REMATCH[2]}"
                    in_array=false
                elif [[ "$line" =~ ^(paths|globs):\ *$ ]]; then
                    in_array=true
                elif [[ "$in_array" == "true" && "$line" =~ ^\ *-\ *\"(.+)\"$ ]]; then
                    [[ -n "$patterns" ]] && patterns="$patterns, "
                    patterns+="${BASH_REMATCH[1]}"
                elif [[ "$line" =~ ^sync:\ *false ]]; then
                    sync="false"
                fi
                continue
            fi
            # No frontmatter at all
            fm_done=true
            RULE_BODY+="$line"$'\n'
        else
            RULE_BODY+="$line"$'\n'
        fi
    done <"$file"

    RULE_PATTERNS="$patterns"
    RULE_SYNC="$sync"
}

# Derive a section title from rule file path
file_to_title() {
    local file="$1"
    local basename dirname
    basename=$(basename "$file" .md)
    dirname=$(basename "$(dirname "$file")")
    if [[ "$dirname" != "rules" ]]; then
        echo "$dirname/$basename"
    else
        echo "$basename"
    fi
}

# --- Global mode: generate merged files for Codex/Copilot ---

generate_global() {
    local global_rules=""
    local lang_rules=""

    while IFS= read -r -d '' file; do
        parse_rule_file "$file"
        [[ "$RULE_SYNC" == "false" ]] && continue

        # Trim leading blank lines
        local body
        body=$(printf '%s' "$RULE_BODY" | sed '/./,$!d')

        if [[ -z "$RULE_PATTERNS" ]]; then
            global_rules+="$body"$'\n\n'
        else
            local title
            title=$(file_to_title "$file")
            lang_rules+="## $title"$'\n\n'
            lang_rules+="Applies to: \`$RULE_PATTERNS\`"$'\n\n'
            lang_rules+="$body"$'\n\n'
        fi
    done < <(find -L "$RULES_DIR" -name '*.md' -print0 | sort -z)

    # --- Codex ---
    mkdir -p "$(dirname "$CODEX_OUT")"
    {
        if [[ -f "$CODEX_HEADER" ]]; then
            cat "$CODEX_HEADER"
            echo ""
            echo "---"
            echo ""
        fi
        echo "<!-- Auto-generated from ~/.claude/rules/ by sync-rules.sh -->"
        echo "<!-- To update: mise run sync-rules -->"
        echo ""
        if [[ -n "$global_rules" ]]; then
            echo "# Global Rules"
            echo ""
            echo "$global_rules"
        fi
        if [[ -n "$lang_rules" ]]; then
            echo "# Language & Domain Rules"
            echo ""
            echo "Apply the rules in each section only when editing files matching the specified patterns."
            echo ""
            echo "$lang_rules"
        fi
    } >"$CODEX_OUT"
    success "Generated $CODEX_OUT"

    # --- Copilot ---
    mkdir -p "$(dirname "$COPILOT_OUT")"
    {
        if [[ -f "$COPILOT_HEADER" ]]; then
            cat "$COPILOT_HEADER"
            echo ""
            echo "---"
            echo ""
        fi
        echo "<!-- Auto-generated from ~/.claude/rules/ by sync-rules.sh -->"
        echo "<!-- To update: mise run sync-rules -->"
        echo ""
        if [[ -n "$global_rules" ]]; then
            echo "# Global Rules"
            echo ""
            echo "$global_rules"
        fi
        if [[ -n "$lang_rules" ]]; then
            echo "# Language & Domain Rules"
            echo ""
            echo "Apply the rules in each section only when editing files matching the specified patterns."
            echo ""
            echo "$lang_rules"
        fi
    } >"$COPILOT_OUT"
    success "Generated $COPILOT_OUT"
}

# --- Project mode: generate native per-project files ---

generate_project() {
    local project_dir="${1:-.}"
    local cursor_dir="$project_dir/.cursor/rules"
    local copilot_dir="$project_dir/.github/instructions"

    mkdir -p "$cursor_dir" "$copilot_dir"

    while IFS= read -r -d '' file; do
        parse_rule_file "$file"
        [[ "$RULE_SYNC" == "false" ]] && continue
        [[ -z "$RULE_PATTERNS" ]] && continue # Skip global rules for per-project

        local basename
        basename=$(basename "$file" .md)
        local dirname
        dirname=$(basename "$(dirname "$file")")
        local name
        if [[ "$dirname" != "rules" ]]; then
            name="${dirname}-${basename}"
        else
            name="$basename"
        fi

        local body
        body=$(echo "$RULE_BODY" | sed '/./,$!d')

        # Cursor: .mdc with globs:
        local cursor_file="$cursor_dir/${name}.mdc"
        {
            echo "---"
            # Convert comma-separated to YAML array
            if [[ "$RULE_PATTERNS" == *","* ]]; then
                echo "globs:"
                IFS=',' read -ra pats <<<"$RULE_PATTERNS"
                for pat in "${pats[@]}"; do
                    pat=$(echo "$pat" | xargs) # trim whitespace
                    echo "  - \"$pat\""
                done
            else
                echo "globs: \"$RULE_PATTERNS\""
            fi
            echo "---"
            echo ""
            echo "$body"
        } >"$cursor_file"
        success "Generated $cursor_file"

        # Copilot: .instructions.md with applyTo:
        local copilot_file="$copilot_dir/${name}.instructions.md"
        local apply_to
        apply_to=$(echo "$RULE_PATTERNS" | sed 's/, */,/g')
        {
            echo "---"
            echo "applyTo: \"$apply_to\""
            echo "---"
            echo ""
            echo "$body"
        } >"$copilot_file"
        success "Generated $copilot_file"
    done < <(find -L "$RULES_DIR" -name '*.md' -print0 | sort -z)

    info "Project rules generated in $project_dir"
}

# --- Main ---

case "${1:---global}" in
    --global)
        info "Syncing rules to Codex/Copilot (global)..."
        generate_global
        ;;
    --project)
        info "Generating project-level rules for Cursor/Copilot..."
        generate_project "${2:-.}"
        ;;
    *)
        echo "Usage: $0 [--global|--project [dir]]"
        exit 1
        ;;
esac
