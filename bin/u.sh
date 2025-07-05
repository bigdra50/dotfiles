#!/bin/bash

# Unity Project Launcher
# Usage: u.sh [path] [--hub]

show_help() {
    echo "Usage: u.sh [path] [--hub]"
    echo "Opens Unity project in the specified directory"
    echo ""
    echo "Options:"
    echo "  path          Unity project path (default: current directory)"
    echo "  --hub         Open with Unity Hub instead of Unity Editor"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  u.sh .        # Open Unity project in current directory with Unity Editor"
    echo "  u.sh ~/MyGame # Open Unity project in ~/MyGame with Unity Editor"
    echo "  u.sh . --hub  # Open Unity project in current directory with Unity Hub"
}

open_unity_project() {
    local project_path="$1"
    local use_hub="$2"
    
    # Convert relative path to absolute path
    if [[ "$project_path" == "." ]]; then
        project_path="$(pwd)"
    elif [[ "$project_path" != /* ]]; then
        project_path="$(pwd)/$project_path"
    fi
    
    # Check if directory exists
    if [[ ! -d "$project_path" ]]; then
        echo "Error: Directory '$project_path' does not exist"
        exit 1
    fi
    
    # Check if it's a Unity project (look for Assets and ProjectSettings directories)
    if [[ ! -d "$project_path/Assets" ]] || [[ ! -d "$project_path/ProjectSettings" ]]; then
        echo "Error: '$project_path' does not appear to be a Unity project"
        echo "Expected to find 'Assets' and 'ProjectSettings' directories"
        exit 1
    fi
    
    # Find Unity Hub or Unity Editor
    local unity_path=""
    
    # Use Unity Hub if --hub flag is specified
    if [[ "$use_hub" == "true" ]]; then
        if command -v "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" >/dev/null 2>&1; then
            echo "Opening Unity project with Unity Hub: $project_path"
            "/Applications/Unity Hub.app/Contents/MacOS/Unity Hub" -- --projectPath "$project_path"
        else
            echo "Error: Unity Hub not found"
            echo "Please make sure Unity Hub is installed in /Applications/Unity Hub.app"
            exit 1
        fi
    # Default: Use Unity Editor directly
    elif [[ -d "/Applications/Unity" ]]; then
        # Find the most recent Unity version
        unity_path=$(find /Applications/Unity -name "Unity.app" -type d | head -1)
        if [[ -n "$unity_path" ]]; then
            echo "Opening Unity project with Unity Editor: $project_path"
            "$unity_path/Contents/MacOS/Unity" -projectPath "$project_path"
        else
            echo "Error: Unity Editor not found in /Applications/Unity"
            exit 1
        fi
    else
        echo "Error: Unity Editor not found"
        echo "Please make sure Unity Editor is installed in /Applications/Unity/"
        exit 1
    fi
}

# Parse command line arguments
project_path="."
use_hub="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --hub)
            use_hub="true"
            shift
            ;;
        -*)
            echo "Error: Unknown option '$1'"
            show_help
            exit 1
            ;;
        *)
            project_path="$1"
            shift
            ;;
    esac
done

# Open the Unity project
open_unity_project "$project_path" "$use_hub"