#Requires -Version 5.1
# Shingle Client Onboarding - opens a pre-filled email with setup instructions
# Usage: .\onboard.ps1 client@email.com "Client Name" [-Mac] [-PracticeArea legal]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Email,

    [Parameter(Position=1)]
    [string]$Name = "there",

    [switch]$Mac,

    [switch]$Linux,

    [ValidateSet("legal", "audit", "policy", "govcon", "educator", "general")]
    [string]$PracticeArea = "general"
)

if ($Linux) {
    $SetupSteps = @"
1. Open a terminal (search for "Terminal" in your app launcher)
2. Copy and paste this command, then press Enter:

   curl -fsSL https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup-linux.sh | bash -s -- $PracticeArea

3. The script will install everything automatically (about 10 minutes)
4. It may ask for your password (to install Docker, VS Code, etc.)
5. If it says you were added to the "docker" group, log out and back in, then run the command again
6. When it finishes, VS Code will open -- click "Reopen in Container"
7. After the container builds (~2 min), type "claude" in the terminal
"@
} elseif ($Mac) {
    $SetupSteps = @"
1. Open Terminal (search for "Terminal" in Spotlight, or look in Applications > Utilities)
2. Copy and paste this command, then press Enter:

   curl -fsSL https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup.sh | bash -s -- $PracticeArea

3. The script will install everything automatically (about 10 minutes)
4. When it finishes, VS Code will open -- click "Reopen in Container"
5. After the container builds (~2 min), type "claude" in the terminal
"@
} else {
    $SetupSteps = @"
1. Open PowerShell (click the Start menu and type "PowerShell", then click it)
2. Copy and paste this command, then press Enter:

   `$env:SHINGLE_AREA='$PracticeArea'; irm https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup.ps1 | iex

3. The script will install everything automatically (about 10 minutes)
4. When it finishes, VS Code will open -- click "Reopen in Container"
5. After the container builds (~2 min), type "claude" in the terminal
"@
}

$Subject = "Your AI Assistant - Setup Instructions"

$Body = @"
Hi $Name,

I've set up an AI assistant for your practice. It runs on your computer, works with your files, and can build tools tailored to your work -- trackers, dashboards, comparison tools, whatever you need.

Setup takes about 10 minutes. Here's what to do:

$SetupSteps

You'll need:
- An internet connection
- About 10 minutes for the initial setup
- A Claude account (the assistant will help you set one up on first launch)

The setup installs Docker, VS Code, and Git, then creates a workspace on your computer. Everything your assistant creates goes into your Documents/ClientWork folder -- regular files you can open, email, or print.

If you need to restart partway through (Windows sometimes requires this for Docker), just run the same command again. It picks up where it left off.

If anything goes wrong, just let me know and I'll walk you through it.

Looking forward to hearing how it goes!
"@

# Copy email body to clipboard and open Gmail compose
$Body | Set-Clipboard

$GmailUrl = "https://mail.google.com/mail/?view=cm&to=$([uri]::EscapeDataString($Email))&su=$([uri]::EscapeDataString($Subject))"
Start-Process $GmailUrl

Write-Host ""
Write-Host "  Gmail compose opened for $Email" -ForegroundColor Green
Write-Host "  Practice area: $PracticeArea" -ForegroundColor Cyan
Write-Host "  Platform: $(if ($Linux) { 'Linux' } elseif ($Mac) { 'Mac' } else { 'Windows' })" -ForegroundColor Cyan
Write-Host "  Email body copied to clipboard -- paste it in (Ctrl+V)." -ForegroundColor Cyan
Write-Host ""
