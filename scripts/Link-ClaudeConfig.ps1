# =============================================================================
# Claude Configuration Symlink Utility
# =============================================================================
# This script creates symlinks for .claude directory contents to ~/.claude/
#
# Usage:
#   .\Link-ClaudeConfig.ps1                    # Interactive mode
#   .\Link-ClaudeConfig.ps1 -Force             # Overwrite existing files
#   .\Link-ClaudeConfig.ps1 -DryRun            # Preview changes only
#   .\Link-ClaudeConfig.ps1 -Selective         # Choose which items to link
#
# Requirements: PowerShell 5.1 or later

#Requires -Version 5.1

param(
    [switch]$Force,
    [switch]$DryRun,
    [switch]$Selective,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# =============================================================================
# Configuration
# =============================================================================

$Script:DotfilesDir = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { $PSScriptRoot | Split-Path -Parent }
$Script:ClaudeSourceDir = Join-Path $Script:DotfilesDir ".claude"
$Script:ClaudeTargetDir = Join-Path $env:USERPROFILE ".claude"

# Items to link (files and directories)
$Script:ClaudeItems = @(
    "CLAUDE.md",
    "agents",
    "commands",
    "settings.json",
    "tools",
    "docs"
)

# =============================================================================
# Helper Functions
# =============================================================================

function Write-Info {
    param([string]$Message)
    Write-Host "==> " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "! " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function New-ClaudeSymlink {
    param(
        [string]$ItemName,
        [switch]$DryRun,
        [switch]$Force
    )

    $source = Join-Path $Script:ClaudeSourceDir $ItemName
    $target = Join-Path $Script:ClaudeTargetDir $ItemName

    # Check if source exists
    if (-not (Test-Path $source)) {
        Write-Warn "Source not found: $ItemName (skipping)"
        return $false
    }

    # Dry run mode
    if ($DryRun) {
        if (Test-Path $target) {
            $item = Get-Item $target
            if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $source) {
                Write-Info "[DRY RUN] $ItemName (already linked correctly)"
            }
            else {
                Write-Warn "[DRY RUN] $ItemName (would be overwritten)"
            }
        }
        else {
            Write-Info "[DRY RUN] $ItemName (would be created)"
        }
        return $true
    }

    # Check if target already exists
    if (Test-Path $target) {
        $item = Get-Item $target

        # Already correctly linked
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $source) {
            Write-Success "$ItemName (already linked)"
            return $true
        }

        # Handle existing file/directory
        if (-not $Force) {
            Write-Warn "$ItemName already exists"
            $response = Read-Host "  Overwrite? [y/N]"
            if ($response -notmatch '^[Yy]$') {
                Write-Warn "Skipping $ItemName"
                return $false
            }
        }

        # Backup existing file/directory
        if ($item.LinkType -ne "SymbolicLink") {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $backup = "$target.backup.$timestamp"
            Move-Item $target $backup -Force
            Write-Info "Backed up to $(Split-Path $backup -Leaf)"
        }
        else {
            Remove-Item $target -Force
        }
    }

    # Create symlink
    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source -Force | Out-Null
        Write-Success $ItemName
        return $true
    }
    catch {
        Write-Err "Failed to create symlink for ${ItemName}: $_"
        return $false
    }
}

# =============================================================================
# Main Function
# =============================================================================

function Show-Help {
    @"
Claude Configuration Symlink Utility

Usage:
  .\Link-ClaudeConfig.ps1 [OPTIONS]

Options:
  -Force              Overwrite existing files without prompting
  -DryRun             Preview changes without making them
  -Selective          Choose which items to link interactively
  -Help               Show this help message

Examples:
  .\Link-ClaudeConfig.ps1                    # Interactive mode
  .\Link-ClaudeConfig.ps1 -Force             # Auto-overwrite
  .\Link-ClaudeConfig.ps1 -DryRun            # Preview only
  .\Link-ClaudeConfig.ps1 -Selective         # Select items

Items that will be linked:
  - CLAUDE.md
  - agents/
  - commands/
  - settings.json
  - tools/
  - docs/

Source: $Script:ClaudeSourceDir
Target: $Script:ClaudeTargetDir
"@
}

function Main {
    if ($Help) {
        Show-Help
        exit 0
    }

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "  🔗 Claude Configuration Symlink Utility   " -ForegroundColor Blue -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    # Check if source directory exists
    if (-not (Test-Path $Script:ClaudeSourceDir)) {
        Write-Err "Source directory not found: $Script:ClaudeSourceDir"
        exit 1
    }

    Write-Info "Source: $Script:ClaudeSourceDir"
    Write-Info "Target: $Script:ClaudeTargetDir"

    if ($DryRun) {
        Write-Info "Mode: DRY RUN (no changes will be made)"
    }
    elseif ($Force) {
        Write-Info "Mode: FORCE (auto-overwrite)"
    }
    elseif ($Selective) {
        Write-Info "Mode: SELECTIVE"
    }
    else {
        Write-Info "Mode: INTERACTIVE"
    }

    # Check for administrator rights
    if (-not $DryRun -and -not (Test-Administrator)) {
        Write-Warn "Not running as Administrator."
        Write-Warn "Symlink creation may fail. Consider running as Administrator."
    }

    Write-Host ""

    # Create target directory if it doesn't exist
    if (-not $DryRun -and -not (Test-Path $Script:ClaudeTargetDir)) {
        Write-Info "Creating target directory: $Script:ClaudeTargetDir"
        New-Item -ItemType Directory -Path $Script:ClaudeTargetDir -Force | Out-Null
    }

    # Selective mode: let user choose items
    $itemsToLink = $Script:ClaudeItems
    if ($Selective -and -not $DryRun) {
        Write-Host "Select items to link:" -ForegroundColor Blue
        $selectedItems = @()
        foreach ($item in $Script:ClaudeItems) {
            $source = Join-Path $Script:ClaudeSourceDir $item
            if (Test-Path $source) {
                $response = Read-Host "  Link $item? [Y/n]"
                if ($response -notmatch '^[Nn]$') {
                    $selectedItems += $item
                }
            }
            else {
                Write-Warn "  $item not found in source (skipping)"
            }
        }
        $itemsToLink = $selectedItems
        Write-Host ""
    }

    # Create symlinks
    Write-Info "Creating symlinks..."
    Write-Host ""

    $successCount = 0
    $failCount = 0

    foreach ($item in $itemsToLink) {
        if (New-ClaudeSymlink -ItemName $item -DryRun:$DryRun -Force:$Force) {
            $successCount++
        }
        else {
            $failCount++
        }
    }

    # Summary
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    if ($DryRun) {
        Write-Host "  📋 Dry Run Complete                       " -ForegroundColor Blue -NoNewline
    }
    else {
        Write-Host "  ✨ Linking Complete                       " -ForegroundColor Green -NoNewline
    }
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Blue
    Write-Host "  Success: $successCount"
    if ($failCount -gt 0) {
        Write-Host "  Failed:  $failCount" -ForegroundColor Red
    }
    Write-Host ""

    if ($DryRun) {
        Write-Info "This was a dry run. Run without -DryRun to apply changes."
        Write-Host ""
    }
}

# Run main function
try {
    Main
}
catch {
    Write-Err "Script failed: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
