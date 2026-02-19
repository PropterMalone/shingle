# Shingle -- Setup Troubleshooter

You're in the bootstrap directory. Setup should have been handled by the setup script automatically. If someone ended up here manually, help them get back on track.

## What to check

1. **Docker Desktop** -- Is it installed and running? Look for the whale icon in the system tray (Windows) or menu bar (Mac). If not installed, they need to re-run the setup command from their onboarding email.

2. **VS Code** -- Is it installed? Can they run `code --version` in a terminal? If not, re-run the setup command.

3. **Dev Containers extension** -- In VS Code, check Extensions (Ctrl+Shift+X / Cmd+Shift+X) for "Dev Containers". Install it if missing: `code --install-extension ms-vscode-remote.remote-containers`

4. **Shingle project** -- Should be at `~/Documents/shingle`. If it's there, open it in VS Code: `code ~/Documents/shingle`. VS Code should prompt to "Reopen in Container" -- click Yes.

## If they need to start over

**Mac:**
```
curl -fsSL https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup.sh | bash
```

**Linux:**
```
curl -fsSL https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup-linux.sh | bash
```

**Windows (PowerShell):**
```
irm https://raw.githubusercontent.com/PropterMalone/shingle/main/bootstrap/setup.ps1 | iex
```

The script skips anything already installed, so re-running is safe.

## Common issues

- **Docker needs a restart (Windows):** Normal on first install. Restart, then re-run the setup command.
- **"code" command not found:** Close the terminal and open a new one, or restart the computer.
- **"Reopen in Container" never appears:** Make sure Dev Containers extension is installed, then use the command palette (Ctrl+Shift+P / Cmd+Shift+P) and search for "Reopen in Container".
