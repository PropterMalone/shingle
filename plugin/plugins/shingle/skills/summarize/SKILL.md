---
name: summarize
description: Create an executive summary of one or more documents
user_invocable: true
---

# Summarize Skill

Create an executive summary of one or more documents.

## Instructions

When invoked:

1. **Get the document(s) to summarize:**
   - Accept a file path or folder path as an argument
   - If no path given, ask the user which documents or folder
   - If a folder path, identify all readable documents in it (`.md`, `.txt`, `.pdf`, etc.)

2. **Read each document completely:**
   - Use the Read tool for each file
   - Understand the full content and context
   - Note connections between documents if multiple

3. **Produce an executive summary with these sections:**

   **Purpose**
   - Why this summary exists
   - What documents it covers (list filenames)
   - Date range if applicable

   **Key Findings**
   - The most important points across all documents
   - Present in priority order (most critical first)
   - Focus on conclusions, decisions, and action items
   - 5-10 bullets maximum

   **Details by Source**
   - For each document, provide a 2-3 sentence summary
   - Include page or section references if helpful
   - Note how each document relates to the overall findings

   **Open Questions**
   - Things that are unclear or incomplete
   - Areas that need follow-up or additional information
   - Contradictions between sources (if multiple documents)

4. **Keep the summary concise:**
   - Target length: 1-2 pages (roughly 500-1000 words)
   - Bottom line first, details second
   - Use bullet points for scannability

5. **Save the summary:**
   - Filename: `Executive-Summary-{YYYY-MM-DD}.md`
   - Save in the same directory as the source documents
   - Use proper markdown formatting

6. **Tell the user:**
   - Confirm the summary filename
   - Offer to expand on any section
   - Ask if they need any specific aspect covered in more depth

## Tone

Crisp, executive-level. Write for someone who has 5 minutes and needs the bottom line first. Be direct and eliminate any fluff. Focus on what matters and what needs to happen next.
