# =============================================================================
# Dotfiles Installation Script for Windows
# =============================================================================
# This script installs and configures dotfiles on Windows
#
# Usage:
#   .\install.ps1                    # Interactive installation
#   $env:INTERACTIVE='false'; .\install.ps1  # Non-interactive installation
#   .\install.ps1 -Help              # Show help
#
# Requirements: PowerShell 5.1 or later

#Requires -Version 5.1

param(
    [switch]$Help,
    [switch]$NonInteractive
)

# =============================================================================
# Configuration
# =============================================================================

$ErrorActionPreference = "Stop"
$Script:ScriptDir = $PSScriptRoot
$Script:DotfilesDir = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { $Script:ScriptDir }
$Script:Interactive = if ($NonInteractive -or $env:INTERACTIVE -eq 'false') { $false } else { $true }

# File exclusion lists
$Script:ExcludeCommon = @(
    ".DS_Store", ".git", ".gitignore", ".gitmodules",
    "README.md", "CLAUDE.md", "install.sh", "install.ps1",
    "bootstrap", "bootstrap.ps1", "justfile", "Makefile",
    "whitelist.sh", "docker-compose.yml", "Dockerfile", "scripts"
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

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# =============================================================================
# Installation Functions
# =============================================================================

function Install-BaseTools {
    Write-Info "Installing base tools..."

    # Install Scoop if not present
    if (-not (Test-CommandExists "scoop")) {
        Write-Info "Installing Scoop package manager..."
        try {
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
            Write-Success "Scoop installed successfully"
        }
        catch {
            Write-Err "Failed to install Scoop: $_"
            return $false
        }
    }
    else {
        Write-Success "Scoop already installed"
    }

    # Add git bucket if needed
    $buckets = scoop bucket list
    if ($buckets -notcontains "main") {
        scoop bucket add main
    }

    # Install git if not present
    if (-not (Test-CommandExists "git")) {
        Write-Info "Installing git..."
        scoop install git
        Write-Success "Git installed"
    }
    else {
        Write-Success "Git already installed"
    }

    return $true
}

function Install-Tools {
    Write-Info "Installing development tools..."

    $toolScript = Join-Path $Script:DotfilesDir "scripts\Install-Tools.ps1"
    if (Test-Path $toolScript) {
        & $toolScript
    }
    else {
        Write-Warn "Install-Tools.ps1 not found or not executable"
    }
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

function Add-Dotfiles {
    Write-Info "Creating symlinks for dotfiles..."

    # Link root-level dotfiles
    Get-ChildItem -Path $Script:DotfilesDir -Hidden -File | ForEach-Object {
        $basename = $_.Name

        # Skip if in exclude list
        if ($Script:ExcludeCommon -contains $basename) {
            return
        }

        $source = $_.FullName
        $target = Join-Path $env:USERPROFILE $basename
        New-SymbolicLink -Source $source -Target $target
    }

    # Link .zsh directory if it exists
    $zshDir = Join-Path $Script:DotfilesDir ".zsh"
    if (Test-Path $zshDir) {
        $target = Join-Path $env:USERPROFILE ".zsh"
        New-SymbolicLink -Source $zshDir -Target $target
    }
}

function Add-ConfigLinks {
    Write-Info "Creating symlinks for .config directory..."

    $configDir = Join-Path $Script:DotfilesDir ".config"
    if (-not (Test-Path $configDir)) {
        return
    }

    $targetConfigDir = Join-Path $env:USERPROFILE ".config"
    if (-not (Test-Path $targetConfigDir)) {
        New-Item -ItemType Directory -Path $targetConfigDir -Force | Out-Null
    }

    Get-ChildItem -Path $configDir -Directory | ForEach-Object {
        $basename = $_.Name

        # Skip backup files and unwanted directories
        if ($basename -match '\.backup\.' -or $basename -eq ".DS_Store") {
            return
        }

        $source = $_.FullName
        $target = Join-Path $targetConfigDir $basename
        New-SymbolicLink -Source $source -Target $target
    }

    # Link .claude directory
    $claudeDir = Join-Path $Script:DotfilesDir ".claude"
    if (Test-Path $claudeDir) {
        $targetClaudeDir = Join-Path $env:USERPROFILE ".claude"
        if (-not (Test-Path $targetClaudeDir)) {
            New-Item -ItemType Directory -Path $targetClaudeDir -Force | Out-Null
        }

        # Link commands directory
        $commandsDir = Join-Path $claudeDir "commands"
        if (Test-Path $commandsDir) {
            $target = Join-Path $targetClaudeDir "commands"
            New-SymbolicLink -Source $commandsDir -Target $target
        }

        # Link docs directory
        $docsDir = Join-Path $claudeDir "docs"
        if (Test-Path $docsDir) {
            $target = Join-Path $targetClaudeDir "docs"
            New-SymbolicLink -Source $docsDir -Target $target
        }
    }
}

function Install-NeovimEnv {
    Write-Info "Setting up Neovim environment..."

    if (-not (Test-CommandExists "uv")) {
        Write-Warn "uv not found, skipping Neovim Python setup"
        return
    }

    # Create venv directory if it doesn't exist
    $venvDir = Join-Path $env:USERPROFILE ".venvs"
    if (-not (Test-Path $venvDir)) {
        New-Item -ItemType Directory -Path $venvDir -Force | Out-Null
    }

    $nvimVenv = Join-Path $venvDir "nvim"

    # Check if nvim venv already exists
    if (Test-Path $nvimVenv) {
        Write-Info "Neovim venv already exists, updating packages..."
    }
    else {
        Write-Info "Creating Neovim Python environment..."
        uv venv $nvimVenv
    }

    # Install neovim package
    Write-Info "Installing neovim Python package..."
    Push-Location $nvimVenv
    uv pip install neovim
    Pop-Location

    Write-Success "Neovim Python environment ready"

    # Install Node.js provider
    if (Test-CommandExists "npm") {
        Write-Info "Installing Neovim Node.js provider..."
        npm install -g neovim@latest
        Write-Success "Neovim Node.js provider installed"
    }
}

# =============================================================================
# Main Installation Process
# =============================================================================

function Show-Help {
    @"
Dotfiles Installation Script for Windows

Usage:
  .\install.ps1 [OPTIONS]

Options:
  -Help              Show this help message
  -NonInteractive    Run in non-interactive mode (auto-accept)

Environment Variables:
  `$env:INTERACTIVE='false'   Run in non-interactive mode
  `$env:DOTFILES_DIR='path'   Override dotfiles directory (default: script directory)

Examples:
  .\install.ps1                              # Interactive installation
  `$env:INTERACTIVE='false'; .\install.ps1    # Non-interactive installation
  `$env:DOTFILES_DIR='C:\dotfiles'; .\install.ps1  # Use custom directory
"@
}

function Main {
    if ($Help) {
        Show-Help
        exit 0
    }

    $startTime = Get-Date

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "  🚀 Dotfiles Installation                  " -ForegroundColor Blue -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Info "Platform: Windows ($env:PROCESSOR_ARCHITECTURE)"
    Write-Info "Dotfiles: $Script:DotfilesDir"
    Write-Info "Interactive: $Script:Interactive"

    # Check for administrator rights for symlink creation
    if (-not (Test-Administrator)) {
        Write-Warn "Not running as Administrator."
        Write-Warn "Symlink creation may fail. Consider running as Administrator."
        Write-Host ""
    }

    Write-Host ""

    # Step 1: Install base tools
    Write-Info "Step 1/5: Installing base tools..."
    Install-BaseTools
    Write-Host ""

    # Step 2: Install development tools
    Write-Info "Step 2/5: Installing development tools..."
    Install-Tools
    Write-Host ""

    # Step 3: Create symlinks
    Write-Info "Step 3/5: Creating symlinks..."
    Add-Dotfiles
    Write-Host ""

    # Step 4: Link .config directory
    Write-Info "Step 4/5: Linking .config directory..."
    Add-ConfigLinks
    Write-Host ""

    # Step 5: Setup Neovim
    Write-Info "Step 5/5: Setting up Neovim..."
    Install-NeovimEnv
    Write-Host ""

    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "  ✨ Installation Completed!                 " -ForegroundColor Green -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📍 Summary:" -ForegroundColor Blue
    Write-Host "  Platform:      Windows ($env:PROCESSOR_ARCHITECTURE)"
    Write-Host "  Dotfiles Dir:  $Script:DotfilesDir"
    Write-Host "  Duration:      $([math]::Round($duration, 2))s"
    Write-Host ""
    Write-Host "📝 Next Steps:" -ForegroundColor Blue
    Write-Host "  1. Restart PowerShell or reload profile:"
    Write-Host "     " -NoNewline
    Write-Host ". `$PROFILE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2. Customize your local settings if needed:"
    Write-Host "     ~/.gitconfig_local"
    Write-Host ""
}

# Run main function
try {
    Main
}
catch {
    Write-Err "Installation failed: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
