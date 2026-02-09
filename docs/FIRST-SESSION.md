# Your First Session with Shingle

This is a 15-minute guided walkthrough. By the end, you'll have used Claude to analyze a document and draft a memo about what you found. Real work, real output.

**Before you start:** Make sure you've followed the [Quick Start Guide](QUICKSTART.md) and have Shingle running in VS Code.

---

## Step 1: Put a Document in Your Folder (2 minutes)

Find a document you want to work with — a contract, a report, a policy memo, anything relevant to your practice. (If you don't have one handy, a PDF you downloaded from a government website works fine.)

1. Open File Explorer on your desktop
2. Copy the document into `Documents\ClientWork`
3. You're done — Claude can see it now

**Tip:** The document can be a PDF, Word doc (.docx), or plain text file. PDFs work best.

---

## Step 2: Review the Document (5 minutes)

Switch back to VS Code. In the Claude prompt, type:

```
/review
```

Claude will ask which document you want to review. Tell it the name of the file you just put in your folder.

Claude will read through the document and produce a structured analysis:
- **Overview** — what the document is, who wrote it, when
- **Summary** — the key points in 3-5 sentences
- **Issues** — anything unclear, missing, or concerning
- **Recommendations** — what you should do next

**What to look for:** Check if Claude caught the main points. Did it flag something you already knew was an issue? Did it spot something you missed?

Claude saves the review as a new file in your ClientWork folder. You'll see it named something like `YourDocument-Review-2026-02-09.md`.

---

## Step 3: Read the Review (2 minutes)

You can read the review in two ways:

**Option A — Inside Claude:** Ask Claude to show you specific sections:
- "What were the main issues you found?"
- "Tell me more about your first recommendation"

**Option B — On your desktop:** Open File Explorer, go to `Documents\ClientWork`, and open the review file. It's a Markdown file — you can read it in any text editor (Notepad works fine).

---

## Step 4: Draft a Memo (5 minutes)

Now let's use what Claude found to write something. Type:

```
/draft
```

Claude will ask you a few questions:
- What kind of document? → **"memo"** (or "letter" or "report")
- Who's the audience? → Tell it (your client, your partner, a regulator)
- What are the key points? → Tell Claude to use the findings from the review

For example, you might say:

> "Draft a memo to my client summarizing the key issues from the contract review we just did. Focus on the top three concerns and recommend next steps."

Claude will:
1. Show you an outline first
2. Ask if it looks right
3. Write the full memo after you approve
4. Save it in your ClientWork folder

---

## Step 5: Find Your Files (1 minute)

Open File Explorer on your desktop and go to `Documents\ClientWork`. You should see:

1. **Your original document** — untouched
2. **The review** — Claude's analysis (e.g., `Contract-Review-2026-02-09.md`)
3. **The memo** — Your new draft (e.g., `Memo-Contract-Issues-Draft-2026-02-09.md`)

These are regular files on your computer. You can:
- Email them to a colleague
- Open them in Word (File > Open, change file type to "All Files")
- Edit them in any text editor
- Print them

---

## What You Just Did

In 15 minutes, you:
- Had an AI assistant read and analyze a document
- Got a structured review with issues and recommendations
- Drafted a client memo based on those findings
- Produced two new work product files sitting in your folder

This is the core Shingle workflow: **read → analyze → draft**. Everything else builds on this.

---

## What to Try Next

**More skills:**
- `/summarize` — Point it at a folder of documents and get a single executive summary
- `/help-me` — If something goes wrong, this creates a diagnostic report for your support person

**Just talk to Claude:**
- "What are the key differences between these two contracts?"
- "Help me prepare interview questions for the CFO about these audit findings"
- "Rewrite the executive summary to be more persuasive"
- "What am I missing in this analysis?"

**Tips for working with Claude:**
- Be specific about what you want: "Draft a 2-page memo" is better than "write something"
- Tell Claude the audience: writing for a judge is different from writing for a project manager
- Ask Claude to revise: "Make the tone more formal" or "Add a section about timeline"
- Claude remembers your conversation — you can refer back to earlier work in the same session

---

## Getting Help

If something isn't working:
1. Type `/help-me` — Claude will gather diagnostic info
2. Check the [troubleshooting section](QUICKSTART.md#troubleshooting) in the Quick Start Guide
3. Send the diagnostic file to your support person
