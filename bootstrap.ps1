# =============================================================================
# Dotfiles Bootstrap Script for Windows
# =============================================================================
# Sets up a new Windows machine: scoop -> git -> clone -> mise -> setup
#
# Usage:
#   irm https://raw.githubusercontent.com/bigdra50/dotfiles/main/bootstrap.ps1 | iex
#   $env:DOTFILES_DIR='C:\custom\path'; irm ... | iex

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$DotfilesRepo = "https://github.com/bigdra50/dotfiles.git"
$DotfilesDir = if ($env:DOTFILES_DIR) { $env:DOTFILES_DIR } else {
    Join-Path $env:USERPROFILE "dev\github.com\bigdra50\dotfiles"
}

function _info { param([string]$m) Write-Host "==> " -ForegroundColor Blue -NoNewline; Write-Host $m }
function _ok   { param([string]$m) Write-Host "[OK] " -ForegroundColor Green -NoNewline; Write-Host $m }
function _err  { param([string]$m) Write-Host "X " -ForegroundColor Red -NoNewline; Write-Host $m }

try {
    # ---- 1. scoop + git ----
    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        _info "Installing Scoop..."
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        _info "Installing git..."
        scoop install git
    }
    _ok "git $(git --version)"

    # ---- 2. Clone/update repo ----
    if (Test-Path (Join-Path $DotfilesDir ".git")) {
        _info "Updating existing repo..."
        Push-Location $DotfilesDir
        git pull --rebase origin main 2>$null
        Pop-Location
    } else {
        _info "Cloning dotfiles..."
        $parentDir = Split-Path $DotfilesDir -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        git clone $DotfilesRepo $DotfilesDir
    }
    _ok "Repo ready at $DotfilesDir"

    # ---- 3. mise ----
    if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
        _info "Installing mise..."
        scoop install mise
    }
    Push-Location $DotfilesDir
    mise trust ".config\mise\config.toml" 2>$null
    mise trust "mise.toml" 2>$null
    _ok "mise $(mise --version)"

    # ---- 4. Setup ----
    _info "Running dotfiles setup..."
    $env:INTERACTIVE = 'false'
    mise run setup

    Pop-Location

    Write-Host ""
    _ok "Bootstrap complete!"
    Write-Host ""
    Write-Host "  Next steps:"
    Write-Host "    1. Restart PowerShell or: . `$PROFILE"
    Write-Host "    2. Customize: ~/.gitconfig_local"
    Write-Host ""
} catch {
    _err "Bootstrap failed: $_"
    Write-Host $_.ScriptStackTrace
    exit 1
}
