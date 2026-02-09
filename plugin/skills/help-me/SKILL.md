---
name: help-me
description: Create a diagnostic snapshot to send to your support person
user_invocable: true
---

# Help Me Skill

Create a diagnostic snapshot to send to your support person.

## Instructions

When invoked:

1. **Ask what went wrong:**
   - "What were you trying to do when something went wrong?"
   - Let them describe the issue in their own words
   - Record their complete answer

2. **Gather diagnostic information automatically:**

   **Documents folder:**
   - List all files in `/workspace/documents/`
   - Include filename, size, and last modified date
   - Note any unusual patterns (very large files, old files, etc.)

   **Configuration:**
   - Check if `CLAUDE.md` exists in the workspace root
   - If it exists, read it and note which practice area is configured
   - Check if API key environment variable is set (just yes/no, NEVER show the actual key)

   **Recent context:**
   - Note any error messages from the current conversation
   - Identify which skill or command was being used when the issue occurred
   - Include any relevant context from recent tool calls

3. **Format the diagnostic report:**

   ```
   SHINGLE DIAGNOSTIC REPORT
   Generated: {date and time}

   WHAT I WAS TRYING TO DO:
   {user's description of the issue}

   DOCUMENTS IN WORKSPACE:
   {file listing with sizes and dates}

   CONFIGURATION:
   - Practice area: {area from CLAUDE.md, or "not configured"}
   - API key configured: yes/no
   - CLAUDE.md present: yes/no

   RECENT CONTEXT:
   {relevant context from conversation}
   - Skill/command in use: {name}
   - Error messages: {if any}
   - What happened: {brief description}

   SYSTEM INFO:
   - Claude Code version: {if available}
   - Plugin version: {from plugin.json}
   ```

4. **Save the diagnostic report:**
   - Filename: `Diagnostic-{YYYY-MM-DD}-{HHMM}.txt`
   - Save in `/workspace/documents/`
   - Plain text format (not markdown)

5. **Tell the user:**
   - "I've saved a diagnostic report to {filename}"
   - "You can send this file to your support person — it contains no sensitive information"
   - "The report includes what you were doing, your workspace setup, and recent context"
   - Offer to answer any other questions about the issue

## Tone

Reassuring and helpful. This person is frustrated or stuck. Don't make them feel stupid. Be calm, clear, and supportive.

## Safety Notes

- NEVER include actual API keys or secrets in the report
- Only confirm yes/no whether credentials are configured
- Don't include full file contents unless specifically relevant to the error
- Focus on metadata and structure, not sensitive data
