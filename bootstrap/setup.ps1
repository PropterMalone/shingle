#Requires -Version 5.1
# Shingle Bootstrap - Windows
# One-command setup: installs everything, opens VS Code at the project.
# Practice area: set $env:SHINGLE_AREA before running (e.g. 'legal', 'audit', 'policy', 'govcon', 'general')
$ErrorActionPreference = "Stop"

$ShingleRepo = "https://github.com/PropterMalone/shingle.git"
$ShingleDir = "$env:USERPROFILE\Documents\shingle"
$PracticeArea = $env:SHINGLE_AREA
$Step = 0
$TotalSteps = 8

# --- Helpers ---
function Refresh-Path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$machinePath;$userPath"
}

function Show-Step {
    param([string]$Label)
    $script:Step++
    Write-Host ""
    Write-Host "  [$Step/$TotalSteps] $Label" -ForegroundColor Cyan
    Start-Sleep -Milliseconds 300
}

function Show-OK {
    param([string]$Message)
    Write-Host "         $Message" -ForegroundColor Green
}

function Show-Action {
    param([string]$Message)
    Write-Host "         $Message" -ForegroundColor White
}

function Show-Warn {
    param([string]$Message)
    Write-Host "         $Message" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host "  Shingle Setup" -ForegroundColor Cyan
Write-Host "  ========================================" -ForegroundColor Cyan
Write-Host ""
Start-Sleep -Milliseconds 500

# --- Step 1: Git ---
Show-Step "Git"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Show-Action "Installing..."
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    if ($hasWinget) {
        winget install Git.Git --accept-source-agreements --accept-package-agreements
        Refresh-Path
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Show-Warn "Could not install Git automatically."
        Show-Warn "Please install from https://git-scm.com/downloads and run this script again."
        exit 1
    }
    Show-OK "Installed."
} else {
    Show-OK "Ready."
}

# --- Step 2: Shingle project ---
Show-Step "Shingle project"
if (Test-Path "$ShingleDir\.git") {
    Show-Action "Checking for updates..."
    try {
        Push-Location $ShingleDir
        git pull --ff-only 2>&1 | Out-Null
    } catch { } finally {
        Pop-Location
    }
    Show-OK "Up to date."
} elseif (Test-Path $ShingleDir) {
    Show-Warn "Folder exists but is not a Git repo."
    Show-Warn "To get automatic updates, delete $ShingleDir and run this script again."
} else {
    Show-Action "Downloading..."
    git clone $ShingleRepo $ShingleDir
    if (-not (Test-Path $ShingleDir)) {
        Show-Warn "Failed to download. Check your internet connection and try again."
        exit 1
    }
    Show-OK "Downloaded."
}

# --- Step 3: Docker Desktop ---
Show-Step "Docker Desktop"
$dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
if (-not $dockerInstalled) {
    Show-Action "Installing... (this may take a few minutes)"
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    if ($hasWinget) {
        winget install Docker.DockerDesktop --accept-source-agreements --accept-package-agreements
        Refresh-Path
    } else {
        Show-Warn "Could not install automatically (winget not available)."
        Show-Warn "Please install from https://www.docker.com/products/docker-desktop/"
        Show-Warn "Then run this script again."
        exit 1
    }

    # Docker Desktop on Windows usually needs a restart on first install
    $dockerReady = $false
    try {
        docker info 2>$null | Out-Null
        $dockerReady = $true
    } catch { }

    if (-not $dockerReady) {
        # Save the re-run command so the user doesn't have to remember it
        $rerunCmd = if ($PracticeArea) {
            "`$env:SHINGLE_AREA='$PracticeArea'; irm https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup.ps1 | iex"
        } else {
            "irm https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup.ps1 | iex"
        }
        $rerunCmd | Set-Clipboard

        Write-Host ""
        Show-OK "Installed."
        Write-Host ""
        Write-Host "  -------------------------------------------------------" -ForegroundColor Yellow
        Show-Warn "Docker needs a restart to finish setting up."
        Show-Warn "Please restart your computer, then:"
        Write-Host ""
        Show-Warn "1. Open PowerShell"
        Show-Warn "2. Paste the command (it's already on your clipboard)"
        Show-Warn "3. Press Enter"
        Write-Host ""
        Show-Warn "Setup will pick up where it left off."
        Write-Host "  -------------------------------------------------------" -ForegroundColor Yellow
        Write-Host ""
        exit 0
    }
    Show-OK "Installed."
} else {
    Show-OK "Installed."
}

# --- Step 4: Docker running ---
Show-Step "Docker engine"
$dockerRunning = $false
try {
    docker info 2>$null | Out-Null
    $dockerRunning = $true
} catch { }

if (-not $dockerRunning) {
    Show-Action "Starting Docker Desktop..."
    $dockerExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    if (Test-Path $dockerExe) {
        Start-Process $dockerExe
    } else {
        Start-Process "shell:AppsFolder\Docker.DockerDesktop" -ErrorAction SilentlyContinue
    }
    $waited = 0
    while ($waited -lt 120) {
        Start-Sleep -Seconds 2
        $waited += 2
        try {
            docker info 2>$null | Out-Null
            $dockerRunning = $true
            break
        } catch { }
    }
    if (-not $dockerRunning) {
        Show-Warn "Docker is installed but not starting."
        Show-Warn "Please open Docker Desktop manually, wait for it to say 'running',"
        Show-Warn "then run this script again."
        exit 0
    }
}
Show-OK "Running."

# --- Step 5: VS Code ---
Show-Step "VS Code"
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Show-Action "Installing..."
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    if ($hasWinget) {
        winget install Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
        Refresh-Path
    } else {
        Show-Warn "Could not install automatically."
        Show-Warn "Please install from https://code.visualstudio.com/ and run this script again."
        exit 1
    }
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Show-Warn "VS Code installed but 'code' command not found."
        Show-Warn "Please close this window, open a new PowerShell, and run this script again."
        exit 1
    }
    Show-OK "Installed."
} else {
    Show-OK "Ready."
}

# --- Step 6: Dev Containers extension ---
Show-Step "Dev Containers extension"
code --install-extension ms-vscode-remote.remote-containers 2>$null
Show-OK "Ready."

# --- Step 7: Claude Code ---
Show-Step "Claude Code"
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Show-OK "Ready."
} else {
    Show-Action "Installing..."
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    if ($hasWinget) {
        winget install Anthropic.ClaudeCode --accept-source-agreements --accept-package-agreements
    } else {
        Show-Warn "Could not install automatically (winget not available)."
        Show-Warn "Please install Claude Code manually:"
        Show-Warn "https://docs.anthropic.com/en/docs/claude-code/getting-started"
        exit 1
    }

    Refresh-Path

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Show-Warn "Installation completed but 'claude' command not found."
        Show-Warn "Please close this window, open a new PowerShell, and run this script again."
        exit 1
    }
    Show-OK "Installed."
}

# --- Ensure HOME is set ---
if (-not $env:HOME) {
    $env:HOME = $env:USERPROFILE
    [System.Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
}

# --- Step 8: Workspace ---
Show-Step "Workspace"
if ($PracticeArea) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.shingle" -Force | Out-Null
    Set-Content -Path "$env:USERPROFILE\.shingle\config" -Value $PracticeArea -NoNewline
    Show-OK "Practice area: $PracticeArea"
}
New-Item -ItemType Directory -Path "$env:USERPROFILE\Documents\ClientWork" -Force | Out-Null
Show-OK "ClientWork folder ready."

# --- Done ---
Write-Host ""
Write-Host "  ========================================" -ForegroundColor Green
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "  ========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  VS Code is opening now. When it asks" -ForegroundColor White
Write-Host "  to 'Reopen in Container' -- click Yes." -ForegroundColor White
Write-Host ""
Write-Host "  After the container builds (~2 min)," -ForegroundColor White
Write-Host "  type 'claude' in the terminal." -ForegroundColor White
Write-Host ""

code $ShingleDir
