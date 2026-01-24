# =============================================================================
# Claude Code Configuration Installation Script for Windows
# =============================================================================
# This script installs Claude Code configuration files
#
# Usage:
#   .\.claude\install.ps1                    # Interactive installation
#   $env:INTERACTIVE='false'; .\.claude\install.ps1  # Non-interactive installation

#Requires -Version 5.1

param(
    [switch]$NonInteractive
)

# =============================================================================
# Configuration
# =============================================================================

$ErrorActionPreference = "Stop"
$Script:ScriptDir = $PSScriptRoot
$Script:ClaudeDir = if ($env:CLAUDE_DIR) { $env:CLAUDE_DIR } else { $Script:ScriptDir }
$Script:Interactive = if ($NonInteractive -or $env:INTERACTIVE -eq 'false') { $false } else { $true }

# Directories to link
$Script:ClaudeDirs = @("commands", "rules", "agents", "skills", "tools", "hooks", "output-styles")

# Files to link
$Script:ClaudeFiles = @("CLAUDE.md", "settings.json", "statusline.sh")

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

function New-SymbolicLink {
    param(
        [string]$Source,
        [string]$Target
    )

    # If target exists
    if (Test-Path $Target) {
        # If it's already the correct symlink, skip
        $item = Get-Item $Target
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $Source) {
            Write-Success "$Target (already linked)"
            return $true
        }

        # Handle based on interactive mode
        if (-not $Script:Interactive) {
            # Non-interactive mode: backup and overwrite
            if ($item.LinkType -ne "SymbolicLink") {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backup = "$Target.backup.$timestamp"
                Move-Item $Target $backup -Force
                Write-Info "Backed up to $backup"
            }
            else {
                Remove-Item $Target -Force
            }
        }
        else {
            # Interactive mode: ask for confirmation
            Write-Warn "$Target already exists"
            $response = Read-Host "  Overwrite? [y/N]"
            if ($response -notmatch '^[Yy]$') {
                Write-Warn "Skipping $Target"
                return $false
            }

            # Backup existing file
            if ($item.LinkType -ne "SymbolicLink") {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backup = "$Target.backup.$timestamp"
                Move-Item $Target $backup -Force
                Write-Info "Backed up to $backup"
            }
            else {
                Remove-Item $Target -Force
            }
        }
    }

    # Create parent directory if needed
    $parentDir = Split-Path $Target -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Create symlink
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        Write-Success $Target
        return $true
    }
    catch {
        Write-Err "Failed to create symlink: $_"
        return $false
    }
}

# =============================================================================
# Installation Functions
# =============================================================================

function Add-ClaudeLinks {
    Write-Info "Creating symlinks for .claude directory..."

    if (-not (Test-Path $Script:ClaudeDir)) {
        Write-Err "Claude directory not found: $Script:ClaudeDir"
        return $false
    }

    $targetClaudeDir = Join-Path $env:USERPROFILE ".claude"
    if (-not (Test-Path $targetClaudeDir)) {
        New-Item -ItemType Directory -Path $targetClaudeDir -Force | Out-Null
    }

    # Link directories
    foreach ($dir in $Script:ClaudeDirs) {
        $sourceDir = Join-Path $Script:ClaudeDir $dir
        if (Test-Path $sourceDir) {
            $target = Join-Path $targetClaudeDir $dir
            New-SymbolicLink -Source $sourceDir -Target $target
        }
    }

    # Link files
    foreach ($file in $Script:ClaudeFiles) {
        $sourceFile = Join-Path $Script:ClaudeDir $file
        if (Test-Path $sourceFile) {
            $target = Join-Path $targetClaudeDir $file
            New-SymbolicLink -Source $sourceFile -Target $target
        }
    }

    return $true
}

# =============================================================================
# Main
# =============================================================================

function Main {
    Write-Info "Claude Code Configuration Installer"
    Write-Info "Source: $Script:ClaudeDir"
    Write-Info "Target: $(Join-Path $env:USERPROFILE '.claude')"
    Write-Info "Interactive: $Script:Interactive"
    Write-Host ""

    Add-ClaudeLinks

    Write-Host ""
    Write-Success "Claude Code configuration installed!"
}

try {
    Main
}
catch {
    Write-Err "Installation failed: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
