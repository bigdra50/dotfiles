$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

$DotfilesDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$ClaudeDir = Join-Path $DotfilesDir ".claude"
$TargetClaudeDir = Join-Path $env:USERPROFILE ".claude"

# Directories to link (skills are managed via npx skills, not symlinked)
$ClaudeDirs = @("commands", "rules", "agents", "tools", "hooks", "output-styles")

# Files to link
$ClaudeFiles = @("CLAUDE.md", "settings.json", "statusline.sh")

# ---- Link claude config ----

Write-Info "Creating symlinks for .claude directory..."

if (-not (Test-Path $ClaudeDir)) {
    Write-Err "Claude directory not found: $ClaudeDir"
    exit 1
}

if (-not (Test-Path $TargetClaudeDir)) {
    New-Item -ItemType Directory -Path $TargetClaudeDir -Force | Out-Null
}

foreach ($dir in $ClaudeDirs) {
    $sourceDir = Join-Path $ClaudeDir $dir
    if (Test-Path $sourceDir) {
        New-DotfileLink -Source $sourceDir -Target (Join-Path $TargetClaudeDir $dir)
    }
}

foreach ($file in $ClaudeFiles) {
    $sourceFile = Join-Path $ClaudeDir $file
    if (Test-Path $sourceFile) {
        New-DotfileLink -Source $sourceFile -Target (Join-Path $TargetClaudeDir $file)
    }
}

# ---- Install skills via npx skills ----

if (Test-CommandExists "npx") {
    Write-Info "Installing skills via npx skills..."
    npx skills add "github:bigdra50/dotfiles" -g -y
    npx skills add "github:bigdra50/unity-cli" -g -y
} else {
    Write-Warn "npx not found, skipping skills installation"
}

Write-Success "Claude Code configuration installed"
