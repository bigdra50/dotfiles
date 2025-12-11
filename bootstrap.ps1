# =============================================================================
# Dotfiles Bootstrap Script for Windows
# =============================================================================
# This script sets up a new Windows machine from scratch
# Requirements: PowerShell 5.1 or later
#
# Usage:
#   irm https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap.ps1 | iex
#   or
#   $env:DOTFILES_DIR='C:\custom\path'; irm ... | iex

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# Configuration
$Script:DotfilesRepo = "https://github.com/bigdra50/dotfiles.git"
$Script:DotfilesDir = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else { Join-Path $env:USERPROFILE "dev\github.com\bigdra50\dotfiles" }

# Retry configuration
$Script:MaxRetries = 4
$Script:RetryDelay = 2

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

function Invoke-RetryCommand {
    param(
        [scriptblock]$Command,
        [int]$MaxAttempts = $Script:MaxRetries,
        [int]$DelaySeconds = $Script:RetryDelay
    )

    $attempt = 1
    $delay = $DelaySeconds

    while ($attempt -le $MaxAttempts) {
        try {
            & $Command
            return $true
        }
        catch {
            if ($attempt -lt $MaxAttempts) {
                Write-Warn "Command failed (attempt $attempt/$MaxAttempts). Retrying in ${delay}s..."
                Start-Sleep -Seconds $delay
                $delay *= 2
                $attempt++
            }
            else {
                Write-Err "Command failed after $MaxAttempts attempts: $_"
                return $false
            }
        }
    }
}

# =============================================================================
# Installation Functions
# =============================================================================

function Install-Git {
    if (Test-CommandExists "git") {
        $version = git --version
        Write-Success "git is already installed ($version)"
        return $true
    }

    Write-Info "Installing git..."

    # Install Scoop first if not present
    if (-not (Test-CommandExists "scoop")) {
        Write-Info "Installing Scoop package manager..."
        try {
            Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
            Write-Success "Scoop installed"
        }
        catch {
            Write-Err "Failed to install Scoop: $_"
            return $false
        }
    }

    # Install git via Scoop
    try {
        scoop install git
        Write-Success "git installed successfully"
        return $true
    }
    catch {
        Write-Err "Failed to install git: $_"
        return $false
    }
}

function Get-DotfilesRepo {
    if (Test-Path $Script:DotfilesDir) {
        Write-Info "Dotfiles directory already exists at $Script:DotfilesDir"
        Push-Location $Script:DotfilesDir

        # Check if it's a git repository
        if (Test-Path ".git") {
            Write-Info "Updating existing repository..."

            # Ensure remote is set correctly
            try {
                $currentRemote = git remote get-url origin 2>$null
                if (-not $currentRemote) {
                    git remote add origin $Script:DotfilesRepo
                }
                elseif ($currentRemote -ne $Script:DotfilesRepo) {
                    Write-Warn "Remote URL mismatch. Updating to $Script:DotfilesRepo"
                    git remote set-url origin $Script:DotfilesRepo
                }

                # Pull latest changes with retry
                $pullCommand = { git pull --rebase origin main 2>&1 }
                if (-not (Invoke-RetryCommand -Command $pullCommand)) {
                    Write-Warn "Failed to pull latest changes. Continuing with existing version..."
                }
            }
            catch {
                Write-Warn "Git operation failed: $_"
            }
        }
        else {
            Write-Warn "Directory exists but is not a git repository. Skipping update."
        }

        Pop-Location
    }
    else {
        Write-Info "Cloning dotfiles repository..."

        # Create parent directory
        $parentDir = Split-Path $Script:DotfilesDir -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # Clone with retry
        $cloneCommand = { git clone $Script:DotfilesRepo $Script:DotfilesDir 2>&1 }
        if (-not (Invoke-RetryCommand -Command $cloneCommand)) {
            Write-Err "Failed to clone repository"
            return $false
        }
    }

    Write-Success "Dotfiles repository ready at $Script:DotfilesDir"
    return $true
}

function Show-Summary {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "  ✨ Bootstrap Completed Successfully!        " -ForegroundColor Green -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📍 Installation Summary:" -ForegroundColor Blue
    Write-Host "  Platform:      Windows ($env:PROCESSOR_ARCHITECTURE)"
    Write-Host "  Dotfiles Dir:  $Script:DotfilesDir"
    Write-Host "  PowerShell:    $($PSVersionTable.PSVersion)"
    Write-Host ""
    Write-Host "📝 Next Steps:" -ForegroundColor Blue
    Write-Host "  1. Restart PowerShell or reload profile:"
    Write-Host "     " -NoNewline
    Write-Host ". `$PROFILE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2. Customize your local settings if needed:"
    Write-Host "     ~/.gitconfig_local"
    Write-Host ""

    # Tips for Windows
    Write-Host "💡 Windows tips:" -ForegroundColor Blue
    Write-Host "  - Consider enabling Developer Mode for better symlink support"
    Write-Host "  - Run PowerShell as Administrator for full functionality"
    Write-Host ""
}

# =============================================================================
# Main Bootstrap Process
# =============================================================================

function Main {
    $startTime = Get-Date

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor Cyan -NoNewline
    Write-Host "  🚀 Dotfiles Bootstrap                     " -ForegroundColor Blue -NoNewline
    Write-Host "║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    Write-Info "Platform: Windows ($env:PROCESSOR_ARCHITECTURE)"

    # Check prerequisites
    Write-Info "Checking prerequisites..."
    Write-Host ""

    # Step 1: Install git if needed
    Write-Info "Step 1/3: Installing git..."
    if (-not (Install-Git)) {
        exit 1
    }
    Write-Host ""

    # Step 2: Clone dotfiles
    Write-Info "Step 2/3: Cloning dotfiles repository..."
    if (-not (Get-DotfilesRepo)) {
        exit 1
    }
    Write-Host ""

    # Step 3: Run install.ps1
    Write-Info "Step 3/3: Running installation..."
    Push-Location $Script:DotfilesDir

    # Run in non-interactive mode for bootstrap
    $env:INTERACTIVE = 'false'

    try {
        $installScript = Join-Path $Script:DotfilesDir "install.ps1"
        if (Test-Path $installScript) {
            & $installScript
            Write-Success "Installation completed!"
        }
        else {
            Write-Err "install.ps1 not found"
            Pop-Location
            exit 1
        }
    }
    catch {
        Write-Err "Installation failed: $_"
        Pop-Location
        exit 1
    }

    Pop-Location
    Write-Host ""

    # Show summary
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds

    Write-Host ""
    Write-Info "Bootstrap completed in $([math]::Round($duration, 2))s"

    Show-Summary
}

# Run main function
try {
    Main
}
catch {
    Write-Err "Bootstrap failed: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
