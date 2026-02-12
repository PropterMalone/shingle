#Requires -Version 5.1
# Shingle Bootstrap - Windows
# Clones the repo, installs Claude Code, and launches the setup assistant.
$ErrorActionPreference = "Stop"

$ShingleRepo = "https://github.com/PropterMalone/shingle.git"
$ShingleDir = "$env:USERPROFILE\Documents\Shingle"

Write-Host ""
Write-Host "  Shingle Setup" -ForegroundColor Cyan
Write-Host "  Preparing your workspace..." -ForegroundColor Gray
Write-Host ""

# --- Install Git (needed for repo clone and future updates) ---
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "  Installing Git..."
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    if ($hasWinget) {
        winget install Git.Git --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
        $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
        $env:PATH = "$machinePath;$userPath"
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "  Could not install Git automatically." -ForegroundColor Yellow
        Write-Host "  Please install Git from https://git-scm.com/downloads and run this script again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    Write-Host "  Git installed." -ForegroundColor Green
} else {
    Write-Host "  Git is already installed." -ForegroundColor Green
}

# --- Clone or update the Shingle repo ---
if (Test-Path "$ShingleDir\.git") {
    Write-Host "  Shingle folder found. Checking for updates..."
    Push-Location $ShingleDir
    git pull --ff-only 2>$null
    Pop-Location
    Write-Host "  Shingle is up to date." -ForegroundColor Green
} elseif (Test-Path $ShingleDir) {
    Write-Host "  Shingle folder exists but is not a Git repo." -ForegroundColor Yellow
    Write-Host "  To get automatic updates, delete $ShingleDir and run this script again." -ForegroundColor Yellow
} else {
    Write-Host "  Downloading Shingle..."
    git clone $ShingleRepo $ShingleDir
    if (-not (Test-Path $ShingleDir)) {
        Write-Host ""
        Write-Host "  Failed to download Shingle." -ForegroundColor Red
        Write-Host "  Check your internet connection and try again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    Write-Host "  Shingle downloaded." -ForegroundColor Green
}

# --- Install Claude Code ---
if (Get-Command claude -ErrorAction SilentlyContinue) {
    Write-Host "  Claude Code is already installed." -ForegroundColor Green
} else {
    Write-Host "  Installing Claude Code..."
    $hasWinget = Get-Command winget -ErrorAction SilentlyContinue
    if ($hasWinget) {
        winget install Anthropic.ClaudeCode --accept-source-agreements --accept-package-agreements
    } else {
        Write-Host ""
        Write-Host "  Could not install automatically (winget not available)." -ForegroundColor Yellow
        Write-Host "  Please install Claude Code manually:" -ForegroundColor Yellow
        Write-Host "  https://docs.anthropic.com/en/docs/claude-code/getting-started" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }

    # Refresh PATH so claude is available in this session
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$machinePath;$userPath"

    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "  Installation completed but 'claude' command not found." -ForegroundColor Red
        Write-Host "  Please close this window, open a new PowerShell, and run this script again." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    Write-Host "  Claude Code installed." -ForegroundColor Green
}

# --- Ensure HOME is set ---
if (-not $env:HOME) {
    $env:HOME = $env:USERPROFILE
    [System.Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
    Write-Host "  HOME environment variable configured." -ForegroundColor Green
}

# --- Launch Claude in the project directory ---
Set-Location $ShingleDir

Write-Host ""
Write-Host "  Starting Claude Code..." -ForegroundColor Cyan
Write-Host "  Claude will walk you through the rest of the setup." -ForegroundColor Gray
Write-Host ""

claude
