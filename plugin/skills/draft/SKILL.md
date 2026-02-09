---
name: draft
description: Write a report, memo, letter, or other deliverable through interactive drafting
user_invocable: true
---

# Draft Skill

Write a report, memo, letter, or other deliverable through interactive drafting.

## Instructions

When invoked:

1. **Start an interactive conversation to understand the deliverable:**

   Ask the user these questions (conversationally, not as a form):
   - What type of document do you need? (memo, report, letter, analysis, proposal section, etc.)
   - Who is the audience? (internal team, client, regulatory body, etc.)
   - What are the key points or conclusions you want to communicate?
   - What tone should this have? (formal, persuasive, neutral, technical, etc.)
   - Are there any reference documents I should draw from?

   If they mention reference documents:
   - Offer to read them
   - Use the Read tool to load relevant context
   - Note key points that should be incorporated

2. **Generate a structured outline:**
   - Present a clear outline with sections and subsections
   - Include brief notes about what each section will cover
   - Format as markdown with headers

3. **Get outline approval:**
   - Ask: "Does this outline look right, or should I adjust anything?"
   - Be prepared to revise sections, reorder, add, or remove
   - Don't proceed to full draft until they approve

4. **Generate the full draft:**
   - Write the complete document following the approved outline
   - Match the requested tone and audience level
   - Include all key points from the conversation
   - Incorporate relevant material from reference documents
   - Use proper document structure (headers, bullets, paragraphs)
   - Add section numbers if appropriate for the document type

5. **Save the draft:**
   - Create descriptive filename: `{Type}-{Topic}-Draft-{YYYY-MM-DD}.md`
   - Example: `Memo-Q1-Performance-Draft-2026-02-09.md`
   - Save in `/workspace/documents/`
   - Use proper markdown formatting

6. **Follow up with the user:**
   - Tell them the filename
   - Offer to revise specific sections
   - Ask if they want you to adjust tone, add details, or restructure

## Tone

**In conversation with the user:** Be collaborative, clear, and helpful. Make this feel like working with a skilled writing partner.

**In the draft itself:** Match the requested tone for the deliverable. Follow professional writing conventions for the document type.

## Tips

- Don't rush the discovery phase. Better to ask clarifying questions than to draft the wrong thing.
- If the user is unsure about structure, suggest standard formats for that document type.
- Be ready to iterate. First drafts are rarely final.
- If you're drawing from reference documents, cite them appropriately.
