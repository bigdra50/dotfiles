$ErrorActionPreference = "Stop"
. "$PSScriptRoot\lib.ps1"

$DotfilesDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

$ExcludeCommon = @(
    ".DS_Store", ".git", ".gitignore", ".gitmodules",
    "README.md", "CLAUDE.md", "install.sh", "install.ps1",
    "bootstrap", "bootstrap.ps1", "docker-compose.yml", "Dockerfile",
    "scripts", "mise.toml"
)

# ---- Root-level dotfiles ----

Write-Info "Creating symlinks for dotfiles..."

Get-ChildItem -Path $DotfilesDir -Hidden -File | ForEach-Object {
    $basename = $_.Name
    if ($ExcludeCommon -contains $basename) { return }

    $source = $_.FullName
    $target = Join-Path $env:USERPROFILE $basename
    New-DotfileLink -Source $source -Target $target
}

# Link .zsh directory
$zshDir = Join-Path $DotfilesDir ".zsh"
if (Test-Path $zshDir) {
    New-DotfileLink -Source $zshDir -Target (Join-Path $env:USERPROFILE ".zsh")
}

# ---- .config directory ----

Write-Info "Creating symlinks for .config directory..."

$configDir = Join-Path $DotfilesDir ".config"
if (Test-Path $configDir) {
    $targetConfigDir = Join-Path $env:USERPROFILE ".config"
    if (-not (Test-Path $targetConfigDir)) {
        New-Item -ItemType Directory -Path $targetConfigDir -Force | Out-Null
    }

    Get-ChildItem -Path $configDir -Directory | ForEach-Object {
        $basename = $_.Name
        if ($basename -match '\.backup\.' -or $basename -eq ".DS_Store") { return }

        $source = $_.FullName
        $target = Join-Path $targetConfigDir $basename
        New-DotfileLink -Source $source -Target $target
    }
}

Write-Success "Symlinks created"
