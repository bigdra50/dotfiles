# =============================================================================
# Dotfiles Installation Script for Windows
# =============================================================================
# Thin wrapper that delegates to mise tasks.
#
# Usage:
#   .\install.ps1                    # Full setup
#   .\install.ps1 -Only symlinks     # Specific steps
#   .\install.ps1 -Help              # Show help

#Requires -Version 5.1

param(
    [switch]$Help,
    [switch]$NonInteractive,
    [string]$Only
)

$ErrorActionPreference = "Stop"

$StepMap = @{
    "base"     = "setup:base"
    "tools"    = "setup:platform-tools"
    "symlinks" = "setup:symlinks"
    "config"   = "setup:symlinks"
    "neovim"   = "setup:neovim"
    "claude"   = "setup:claude"
}

function Show-Help {
    @"
Dotfiles Installation Script for Windows

Usage:
  .\install.ps1 [OPTIONS]

Options:
  -Help              Show this help message
  -NonInteractive    Run in non-interactive mode
  -Only STEPS        Run only specific steps (comma-separated)
                     Available: base, tools, symlinks, neovim, claude

Examples:
  .\install.ps1                              # Full installation
  .\install.ps1 -Only symlinks               # Symlinks only
  .\install.ps1 -Only "symlinks,claude"      # Multiple steps
  `$env:INTERACTIVE='false'; .\install.ps1   # Non-interactive
"@
}

if ($Help) { Show-Help; exit 0 }

if ($NonInteractive) { $env:INTERACTIVE = 'false' }

Push-Location $PSScriptRoot

# Ensure mise is available
if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        scoop install mise
    } else {
        Write-Host "mise not found. Install scoop first: https://get.scoop.sh" -ForegroundColor Red
        exit 1
    }
}

mise trust ".config\mise\config.toml" 2>$null
mise trust "mise.toml" 2>$null

if ($Only) {
    $steps = $Only -split ','
    foreach ($step in $steps) {
        $task = if ($StepMap.ContainsKey($step.Trim())) { $StepMap[$step.Trim()] } else { "setup:$($step.Trim())" }
        mise run $task
    }
} else {
    mise run setup
}

Pop-Location
