$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

Write-Info "Installing base tools for Windows..."

if (-not (Test-CommandExists "scoop")) {
    Write-Info "Installing Scoop package manager..."
    try {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Success "Scoop installed"
    } catch {
        Write-Err "Failed to install Scoop: $_"
        exit 1
    }
} else {
    Write-Success "Scoop already installed"
}

$buckets = scoop bucket list
if ($buckets -notcontains "main") {
    scoop bucket add main
}

if (-not (Test-CommandExists "git")) {
    Write-Info "Installing git..."
    scoop install git
    Write-Success "Git installed"
} else {
    Write-Success "Git already installed"
}

Write-Success "Base tools installed"
