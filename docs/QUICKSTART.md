# Shingle Quick Start Guide

Get your AI consulting assistant set up in about 10 minutes.

---

## What You'll Need

- A computer running **Windows 10/11** or **macOS**
- An internet connection
- The **setup.ps1** file your support person sent you
- A **Claude account** with a Pro or Max subscription (the assistant will help you create one if needed)

You do NOT need to install anything yourself. The setup assistant handles everything.

---

## Step 1: Run the Setup Script

**On Windows:**
1. Save the `setup.ps1` file your support person emailed you to your Desktop
2. Right-click it and select **Run with PowerShell**
   - If Windows asks for permission, click **Yes** or **Run anyway**

**On Mac:**
1. Open **Terminal** (search for it in Spotlight)
2. Type this command and press Enter:
   ```
   bash ~/Desktop/setup.sh
   ```

The script will download Shingle and install Claude Code automatically.

---

## Step 2: Follow the Setup Assistant

After the script runs, Claude (your setup assistant) will appear and walk you through:

1. **Installing Docker** — creates the isolated workspace for your assistant
2. **Installing VS Code** — the window where you'll work
3. **Setting up your Claude account** — connects your assistant to Anthropic's AI
4. **Creating your ClientWork folder** — where your documents and tools will live
5. **Choosing your practice area** — configures your assistant for your field

Just follow along and answer the questions. The assistant explains everything.

**Note:** If the assistant says you need to restart your computer (this happens on Windows when Docker is first installed), go ahead and restart. Then run the setup script again — it will pick up where it left off.

---

## Step 3: Open Your Workspace

Once setup is complete, the assistant will tell you to:

1. **Open VS Code**
2. Click **File > Open Folder** and select the **shingle** folder (in your Documents)
3. VS Code will ask to **"Reopen in Container"** — click **Yes**
4. Wait 2-3 minutes the first time (it's building your workspace)
5. When you see a welcome message in the terminal, type: **claude**
6. Claude will show a **login URL** — open it in your browser and authorize

You're ready to work!

---

## Your Files

| Location | What's There |
|----------|-------------|
| `Documents\ClientWork` (on your desktop) | Your working documents and tools — put files here for your assistant to work with |
| Inside the workspace: `/workspace/documents/` | Same folder, accessed from inside your assistant's workspace |

Everything your assistant creates goes into your `ClientWork` folder. You can open these files from your regular desktop too.

---

## Troubleshooting

**Setup script won't run (Windows):**
- Right-click the script, select "Properties", and check "Unblock" at the bottom
- Or open PowerShell manually and type: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`

**Claude login URL doesn't open automatically:**
- This is normal inside the container. Copy the URL shown in the terminal and paste it into your browser (Chrome, Edge, Firefox)
- After you authorize in the browser, the terminal will continue automatically

**Container won't start:**
- Make sure Docker Desktop is running (check the system tray / menu bar)
- Try restarting Docker Desktop
- In VS Code: press `Ctrl+Shift+P`, type "Rebuild", select "Dev Containers: Rebuild Container"

**Something else went wrong:**
- Describe the problem to your assistant — it will help you troubleshoot
- If the assistant can't resolve it, it will gather diagnostic information you can send to your support person

---

## What's Next?

Read [Your First Session](FIRST-SESSION.md) for a guided 15-minute walkthrough that shows you how to do real work with your assistant.
