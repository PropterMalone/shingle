# Shingle Quick Start Guide

This guide will get you up and running with Shingle in about 10 minutes. No technical experience needed.

---

## What You Need

Before starting, install these three programs. Click each link and follow the installer.

1. **Docker Desktop** — [Download here](https://www.docker.com/products/docker-desktop/)
   - This runs the isolated workspace where Claude lives
   - During install, accept all default settings
   - After install, open Docker Desktop and let it finish starting up (you'll see a green "running" indicator)

2. **VS Code** — [Download here](https://code.visualstudio.com/)
   - This is the window where you'll interact with Claude
   - During install, check "Add to PATH" if asked

3. **Dev Containers extension** — [Install from here](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   - Click the green "Install" button on the page
   - It will open VS Code and install automatically

---

## Set Up Your API Key

Claude needs an API key to work. You'll do this once.

1. Go to [console.anthropic.com](https://console.anthropic.com/)
2. Create an account or sign in
3. Click **API Keys** in the left sidebar
4. Click **Create Key** and give it a name like "Shingle"
5. Copy the key (it starts with `sk-ant-`)

Now save the key to a file on your computer:

1. Open File Explorer
2. Navigate to your home folder (usually `C:\Users\YourName`)
3. Create a new folder called `.shingle` (note the dot at the beginning)
   - If Windows won't let you create a folder starting with a dot, open Notepad, save a blank file as `.shingle\env`, and it will create both
4. Inside the `.shingle` folder, create a file called `env` (no extension)
5. Open `env` with Notepad and type this single line:

```
ANTHROPIC_API_KEY=sk-ant-paste-your-key-here
```

6. Save and close

---

## Create Your Documents Folder

Shingle works with documents in a specific folder on your computer.

1. Open File Explorer
2. Go to `Documents` (your regular Documents folder)
3. Create a new folder called `ClientWork`

This is where you'll put documents you want Claude to help with, and where Claude will save its work.

---

## Open Shingle

1. Open VS Code
2. Click **File** > **Open Folder**
3. Navigate to where you saved the Shingle project and open it
4. VS Code will show a notification in the bottom-right corner:
   > "Folder contains a Dev Container configuration file. Reopen folder to develop in a container."
5. Click **Reopen in Container**

**First time only:** This takes 2-3 minutes while it sets up. You'll see progress in the bottom-left corner. Go get a coffee.

When it's done, you'll see a terminal at the bottom of VS Code with a welcome message.

---

## Start Using Claude

In the terminal at the bottom of VS Code, type:

```
claude
```

Press Enter. Claude will start up and you'll see a prompt where you can type.

**First time:** Shingle will ask what kind of consulting you do. Pick your practice area (1-5) and press Enter. This sets up Claude with instructions specific to your work.

Now you're ready! Try one of these:

- Type `/review` to analyze a document
- Type `/summarize` to create an executive summary
- Type `/draft` to write a memo or report
- Type `help me with [your question]` for general help

---

## Your Files

| Location | What's There |
|----------|-------------|
| `Documents\ClientWork` (on your desktop) | Your working documents — these persist even if you rebuild the container |
| Inside the container: `/workspace/documents/` | Same folder, accessed from inside Claude's workspace |

Everything Claude creates goes into your `ClientWork` folder. You can open these files from your regular desktop too.

---

## Troubleshooting

**"API Key Not Found" message:**
- Double-check that `C:\Users\YourName\.shingle\env` exists and contains your key
- Make sure the file is called `env` with no extension (not `env.txt`)
- Rebuild the container: press `Ctrl+Shift+P`, type "Rebuild", and select "Dev Containers: Rebuild Container"

**Container won't start:**
- Make sure Docker Desktop is running (check the system tray)
- Try restarting Docker Desktop
- Try: `Ctrl+Shift+P` > "Dev Containers: Rebuild Container Without Cache"

**Claude says it can't find your documents:**
- Make sure you have a `ClientWork` folder inside your `Documents` folder
- Put at least one file in it before starting

**Something else went wrong:**
- Type `/help-me` inside Claude — it will create a diagnostic report you can send to your support person

---

## What's Next?

Read [FIRST-SESSION.md](FIRST-SESSION.md) for a guided 15-minute walkthrough that shows you how to do real work with Claude.
