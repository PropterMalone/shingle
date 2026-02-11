#Requires -Version 5.1
# Shingle Bootstrap - Windows
# Installs Claude Code and launches the setup assistant.
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  Shingle Setup" -ForegroundColor Cyan
Write-Host "  Preparing your workspace..." -ForegroundColor Gray
Write-Host ""

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

# --- Ensure HOME is set (VS Code devcontainers use ${localEnv:HOME} for mounts) ---
if (-not $env:HOME) {
    $env:HOME = $env:USERPROFILE
    [System.Environment]::SetEnvironmentVariable("HOME", $env:USERPROFILE, "User")
    Write-Host "  HOME environment variable configured." -ForegroundColor Green
}

# --- Launch Claude in the project directory ---
$projectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectDir

Write-Host ""
Write-Host "  Starting Claude Code..." -ForegroundColor Cyan
Write-Host "  Claude will walk you through the rest of the setup." -ForegroundColor Gray
Write-Host ""

claude
