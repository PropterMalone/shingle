#!/usr/bin/env bash
# Shingle Bootstrap - Mac/Linux
# Clones the repo, installs Claude Code, and launches the setup assistant.
set -euo pipefail

SHINGLE_REPO="https://github.com/PropterMalone/shingle.git"
SHINGLE_DIR="$HOME/Documents/shingle"

echo ""
echo "  Shingle Setup"
echo "  Preparing your workspace..."
echo ""

# --- Install Git (needed for repo clone and future updates) ---
if command -v git &>/dev/null; then
    echo "  Git is already installed."
else
    echo "  Installing Git..."
    # macOS: xcode-select --install provides git
    if [[ "$(uname)" == "Darwin" ]]; then
        # Check if Xcode CLI tools are available (git comes with them)
        if xcode-select -p &>/dev/null; then
            echo "  Xcode command line tools found but git not in PATH. Trying rehash..."
        else
            echo "  Installing Xcode command line tools (includes Git)..."
            echo "  A dialog may appear — click 'Install' and wait for it to finish."
            xcode-select --install 2>/dev/null || true
            echo ""
            echo "  After the install finishes, run this script again:"
            echo "  bash ~/Desktop/setup.sh"
            echo ""
            exit 0
        fi
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y git
    elif command -v brew &>/dev/null; then
        brew install git
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

# --- Clone or update the Shingle repo ---
if [[ -d "$SHINGLE_DIR/.git" ]]; then
    echo "  Shingle folder found. Checking for updates..."
    git -C "$SHINGLE_DIR" pull --ff-only 2>/dev/null || true
    echo "  Shingle is up to date."
elif [[ -d "$SHINGLE_DIR" ]]; then
    echo "  Shingle folder exists but is not a Git repo."
    echo "  To get automatic updates, delete $SHINGLE_DIR and run this script again."
else
    echo "  Downloading Shingle..."
    # Ensure Documents directory exists (some Mac setups don't have it)
    mkdir -p "$HOME/Documents"
    git clone "$SHINGLE_REPO" "$SHINGLE_DIR"
    if [[ ! -d "$SHINGLE_DIR" ]]; then
        echo ""
        echo "  Failed to download Shingle."
        echo "  Check your internet connection and try again."
        echo ""
        exit 1
    fi
    echo "  Shingle downloaded."
fi

# --- Install Claude Code ---
if command -v claude &>/dev/null; then
    echo "  Claude Code is already installed."
else
    echo "  Installing Claude Code..."
    if command -v curl &>/dev/null; then
        curl -fsSL https://claude.ai/install.sh | sh
    else
        echo ""
        echo "  Could not install automatically (curl not available)."
        echo "  Please install Claude Code manually:"
        echo "  https://docs.anthropic.com/en/docs/claude-code/getting-started"
        echo ""
        exit 1
    fi

    # Add common install locations to PATH
    export PATH="$HOME/.local/bin:$HOME/.claude/bin:/usr/local/bin:$PATH"

    if ! command -v claude &>/dev/null; then
        echo ""
        echo "  Installation completed but 'claude' command not found."
        echo "  Please close this terminal, open a new one, and run this script again."
        echo ""
        exit 1
    fi
    echo "  Claude Code installed."
fi

# --- Launch Claude in the bootstrap directory ---
# Claude reads CLAUDE.md from its working directory. bootstrap/CLAUDE.md
# contains the Phase 1 setup assistant instructions.
cd "$SHINGLE_DIR/bootstrap"

echo ""
echo "  Starting Claude Code..."
echo "  Claude will walk you through the rest of the setup."
echo ""

claude
