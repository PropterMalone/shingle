#!/usr/bin/env bash
# Shingle Bootstrap - Mac
# One-command setup: installs everything, opens VS Code at the project.
# Usage: curl ... | bash -s -- [practice-area]
set -euo pipefail

SHINGLE_REPO="https://github.com/PropterMalone/shingle.git"
SHINGLE_DIR="$HOME/Documents/shingle"
PRACTICE_AREA="${1:-}"

echo ""
echo "  Shingle Setup"
echo "  Preparing your workspace..."
echo ""

# --- Install Xcode CLI tools (provides Git) ---
if command -v git &>/dev/null; then
    echo "  Git is already installed."
else
    if xcode-select -p &>/dev/null; then
        echo "  Xcode command line tools found but git not in PATH. Trying rehash..."
    else
        echo "  Installing Xcode command line tools (includes Git)..."
        xcode-select --install 2>/dev/null || true
        echo ""
        echo "  !! ACTION NEEDED !!"
        echo "  -------------------------------------------------------"
        echo "  A dialog box appeared -- check BEHIND this window."
        echo "  It says 'Install Command Line Developer Tools'."
        echo "  Click 'Install' and wait for it to finish."
        echo "  -------------------------------------------------------"
        echo ""
        echo "  When it's done, run the setup command again."
        echo ""
        exit 0
    fi

    if ! command -v git &>/dev/null; then
        echo ""
        echo "  Could not install Git automatically."
        echo "  Please install Git from https://git-scm.com/downloads and run this script again."
        echo ""
        exit 1
    fi
    echo "  Git installed."
fi

# --- Install Homebrew ---
if command -v brew &>/dev/null; then
    echo "  Homebrew is already installed."
else
    echo "  Installing Homebrew... (will ask for your password)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Handle Apple Silicon vs Intel PATH
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    if ! command -v brew &>/dev/null; then
        echo ""
        echo "  Homebrew installed but not in PATH."
        echo "  Please close this terminal, open a new one, and run the setup command again."
        echo ""
        exit 1
    fi
    echo "  Homebrew installed."
fi

# --- Clone or update the Shingle repo ---
if [[ -d "$SHINGLE_DIR/.git" ]]; then
    echo "  Shingle folder found. Checking for updates..."
    git -C "$SHINGLE_DIR" pull --ff-only 2>/dev/null || true
    echo "  Shingle is up to date."
elif [[ -d "$SHINGLE_DIR" ]]; then
    echo "  Shingle folder exists but is not a Git repo."
    echo "  To get automatic updates, delete $SHINGLE_DIR and run this script again."
else
    echo "  Downloading Shingle... (this may take a moment)"
    mkdir -p "$HOME/Documents"
    git clone --progress "$SHINGLE_REPO" "$SHINGLE_DIR"
    if [[ ! -d "$SHINGLE_DIR" ]]; then
        echo ""
        echo "  Failed to download Shingle."
        echo "  Check your internet connection and try again."
        echo ""
        exit 1
    fi
    echo "  Shingle downloaded."
fi

# --- Install Docker Desktop ---
if command -v docker &>/dev/null; then
    echo "  Docker is already installed."
else
    echo "  Installing Docker Desktop... (this may take a few minutes)"
    brew install --cask docker
    echo "  Docker installed. Starting it up..."
    open -a Docker
    echo "  Waiting for Docker to be ready..."
    for i in {1..120}; do
        if docker info &>/dev/null 2>&1; then
            break
        fi
        if [[ $i -eq 120 ]]; then
            echo ""
            echo "  Docker is installed but taking a while to start."
            echo "  Look for the Docker whale icon in your menu bar."
            echo "  Once it says 'Docker Desktop is running', run the setup command again."
            echo ""
            exit 0
        fi
        sleep 1
    done
    echo "  Docker is running."
fi

# --- Start Docker if not running ---
if ! docker info &>/dev/null 2>&1; then
    echo "  Starting Docker Desktop..."
    open -a Docker
    for i in {1..120}; do
        if docker info &>/dev/null 2>&1; then
            break
        fi
        if [[ $i -eq 120 ]]; then
            echo ""
            echo "  Docker is installed but won't start."
            echo "  Try opening Docker Desktop from your Applications folder."
            echo "  Once it's running, run the setup command again."
            echo ""
            exit 0
        fi
        sleep 1
    done
    echo "  Docker is running."
fi

# --- Install VS Code ---
if command -v code &>/dev/null; then
    echo "  VS Code is already installed."
else
    echo "  Installing VS Code..."
    brew install --cask visual-studio-code
    if ! command -v code &>/dev/null; then
        echo ""
        echo "  VS Code installed but 'code' command not found."
        echo "  Please close this terminal, open a new one, and run the setup command again."
        echo ""
        exit 1
    fi
    echo "  VS Code installed."
fi

# --- Install Dev Containers extension ---
echo "  Checking Dev Containers extension..."
code --install-extension ms-vscode-remote.remote-containers 2>/dev/null || true

# --- Install Claude Code ---
if command -v claude &>/dev/null; then
    echo "  Claude Code is already installed."
else
    echo "  Installing Claude Code... (this may take a minute)"
    curl -fsSL https://claude.ai/install.sh | sh

    export PATH="$HOME/.local/bin:$HOME/.claude/bin:/usr/local/bin:$PATH"

    if ! command -v claude &>/dev/null; then
        echo ""
        echo "  Installation completed but 'claude' command not found."
        echo "  Please close this terminal, open a new one, and run the setup command again."
        echo ""
        exit 1
    fi
    echo "  Claude Code installed."
fi

# --- Practice area ---
if [[ -n "$PRACTICE_AREA" ]]; then
    mkdir -p ~/.shingle
    echo "$PRACTICE_AREA" > ~/.shingle/config
    echo "  Practice area set to: $PRACTICE_AREA"
fi

# --- Create ClientWork folder ---
mkdir -p ~/Documents/ClientWork

# --- Open VS Code at the project ---
echo ""
echo "  ======================================================="
echo "  Setup complete! VS Code is opening now."
echo ""
echo "  1. Click 'Reopen in Container' when VS Code prompts you"
echo "  2. Wait about 2 minutes for the container to build"
echo "  3. Type 'claude' in the terminal that appears"
echo "  ======================================================="
echo ""
code "$SHINGLE_DIR"
