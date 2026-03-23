# Shared PowerShell helpers for setup scripts
# Usage: . "$PSScriptRoot\lib.ps1"

# Guard against multiple sourcing
if ($Script:_LibPs1Loaded) { return }
$Script:_LibPs1Loaded = $true

function Write-Info {
    param([string]$Message)
    Write-Host "==> " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "! " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "X " -ForegroundColor Red -NoNewline
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

function New-DotfileLink {
    param(
        [string]$Source,
        [string]$Target
    )

    $interactive = $env:INTERACTIVE -ne 'false'

    # If target exists
    if (Test-Path $Target) {
        $item = Get-Item $Target
        # Already correctly linked
        if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $Source) {
            Write-Success "$Target (already linked)"
            return $true
        }

        if (-not $interactive) {
            if ($item.LinkType -ne "SymbolicLink") {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backup = "$Target.backup.$timestamp"
                Move-Item $Target $backup -Force
                Write-Info "Backed up to $backup"
            } else {
                Remove-Item $Target -Force
            }
        } else {
            Write-Warn "$Target already exists"
            $response = Read-Host "  Overwrite? [y/N]"
            if ($response -notmatch '^[Yy]$') {
                Write-Warn "Skipping $Target"
                return $false
            }
            if ($item.LinkType -ne "SymbolicLink") {
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $backup = "$Target.backup.$timestamp"
                Move-Item $Target $backup -Force
                Write-Info "Backed up to $backup"
            } else {
                Remove-Item $Target -Force
            }
        }
    }

    # Create parent directory if needed
    $parentDir = Split-Path $Target -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Try symlink, fallback to junction/hardlink
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $Source -Force | Out-Null
        Write-Success $Target
        return $true
    } catch {
        try {
            if (Test-Path $Source -PathType Container) {
                cmd /c "mklink /J `"$Target`" `"$Source`"" 2>$null | Out-Null
                Write-Success "$Target (junction)"
            } else {
                cmd /c "mklink /H `"$Target`" `"$Source`"" 2>$null | Out-Null
                Write-Success "$Target (hardlink)"
            }
            return $true
        } catch {
            Write-Err "Failed to create link: $_"
            return $false
        }
    }
}
