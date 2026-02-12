#Requires -Version 5.1
# Shingle Client Onboarding - opens a pre-filled email with setup instructions
# Usage: .\onboard.ps1 client@email.com "Client Name" [-Mac]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Email,

    [Parameter(Position=1)]
    [string]$Name = "there",

    [switch]$Mac
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($Mac) {
    $SetupScript = Join-Path $ScriptDir "setup.sh"
    $ScriptName = "setup.sh"
    $SetupSteps = @"
1. Save the attached file (setup.sh) to your Desktop
2. Open Terminal (search for it in Spotlight)
3. Type this command and press Enter: bash ~/Desktop/setup.sh
4. Follow the assistant's instructions - it will walk you through everything
"@
} else {
    $SetupScript = Join-Path $ScriptDir "setup.ps1"
    $ScriptName = "setup.ps1"
    $SetupSteps = @"
1. Save the attached file (setup.ps1) to your Desktop
2. Right-click it and select "Run with PowerShell"
3. Follow the assistant's instructions - it will walk you through everything
"@
}

if (-not (Test-Path $SetupScript)) {
    Write-Host "  Error: $ScriptName not found at $SetupScript" -ForegroundColor Red
    exit 1
}

$Subject = "Your AI Assistant - Setup Instructions"

$Body = @"
Hi $Name,

I've set up an AI assistant for your practice. It runs on your computer, works with your files, and can build tools tailored to your work - trackers, dashboards, comparison tools, whatever you need.

Setup takes about 10 minutes. Here's what to do:

$SetupSteps

You'll need:
- An internet connection
- About 10 minutes for the initial setup
- A Claude account (the assistant will help you create one if needed)

The setup will install a few programs (Docker, VS Code, Git) and create a workspace on your computer. Everything your assistant creates goes into your Documents/ClientWork folder - regular files you can open, email, or print.

If anything goes wrong during setup, the assistant will tell you what to do. If you get stuck, just let me know and I'll walk you through it.

Looking forward to hearing how it goes!
"@

# Copy email body to clipboard and open Gmail compose
$Body | Set-Clipboard

$GmailUrl = "https://mail.google.com/mail/?view=cm&to=$([uri]::EscapeDataString($Email))&su=$([uri]::EscapeDataString($Subject))"
Start-Process $GmailUrl

Write-Host ""
Write-Host "  Gmail compose opened for $Email" -ForegroundColor Green
Write-Host "  Email body copied to clipboard - paste it in (Ctrl+V)." -ForegroundColor Cyan
Write-Host "  Attach this file: $SetupScript" -ForegroundColor Cyan
Write-Host ""
