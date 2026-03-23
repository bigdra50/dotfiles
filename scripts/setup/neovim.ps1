$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

Write-Info "Setting up Neovim environment..."

if (-not (Test-CommandExists "uv")) {
    Write-Warn "uv not found, skipping Neovim Python setup"
    exit 0
}

$venvDir = Join-Path $env:USERPROFILE ".venvs"
if (-not (Test-Path $venvDir)) {
    New-Item -ItemType Directory -Path $venvDir -Force | Out-Null
}

$nvimVenv = Join-Path $venvDir "nvim"

if (Test-Path $nvimVenv) {
    Write-Info "Neovim venv already exists, updating packages..."
} else {
    Write-Info "Creating Neovim Python environment..."
    uv venv $nvimVenv
}

Write-Info "Installing neovim Python package..."
Push-Location $nvimVenv
uv pip install neovim
Pop-Location

Write-Success "Neovim Python environment ready"

if (Test-CommandExists "npm") {
    Write-Info "Installing Neovim Node.js provider..."
    npm install -g neovim@latest
    Write-Success "Neovim Node.js provider installed"
}
