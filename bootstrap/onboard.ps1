#Requires -Version 5.1
# Shingle Client Onboarding — opens a pre-filled email with setup instructions
# Usage: .\onboard.ps1 client@email.com "Client Name"
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Email,

    [Parameter(Position=1)]
    [string]$Name = "there"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SetupScript = Join-Path $ScriptDir "setup.ps1"

if (-not (Test-Path $SetupScript)) {
    Write-Host "  Error: setup.ps1 not found at $SetupScript" -ForegroundColor Red
    exit 1
}

$Subject = "Your AI Document Assistant — Setup Instructions"

$Body = @"
Hi $Name,

I've set up an AI document assistant for your practice. It runs on your computer, works with your files, and is configured for your field.

Setup takes about 10 minutes. Here's what to do:

1. Save the attached file (setup.ps1) to your Desktop
2. Right-click it and select "Run with PowerShell"
3. Follow the assistant's instructions — it will walk you through everything

You'll need:
- An internet connection
- About 10 minutes for the initial setup
- A Claude account (the assistant will help you create one if needed)

The setup will install a few programs (Docker, VS Code, Git) and create a workspace on your computer. Everything your assistant creates goes into your Documents\ClientWork folder — regular files you can open, email, or print.

If anything goes wrong during setup, the assistant will tell you what to do. If you get stuck, just let me know and I'll walk you through it.

Looking forward to hearing how it goes!
"@

# Copy email body to clipboard and open Gmail compose
$Body | Set-Clipboard

$GmailUrl = "https://mail.google.com/mail/?view=cm&to=$([uri]::EscapeDataString($Email))&su=$([uri]::EscapeDataString($Subject))"
Start-Process $GmailUrl

Write-Host ""
Write-Host "  Gmail compose opened for $Email" -ForegroundColor Green
Write-Host "  Email body copied to clipboard — paste it in (Ctrl+V)." -ForegroundColor Cyan
Write-Host "  Attach this file: $SetupScript" -ForegroundColor Cyan
Write-Host ""
