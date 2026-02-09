---
name: review
description: Analyze a document and produce a structured review
user_invocable: true
---

# Review Skill

Analyze a document and produce a structured review.

## Instructions

When invoked:

1. **Get the document to review:**
   - If a file path was provided as an argument, use it
   - Otherwise, list files in `/workspace/documents/` and ask the user which one to review

2. **Read the document thoroughly:**
   - Use the Read tool to load the complete file
   - Understand the content, context, and purpose

3. **Produce a structured review with these sections:**

   **Document Overview**
   - What type of document is this?
   - Who wrote it (if apparent from content)?
   - Date (if mentioned or from filename)?
   - Length and scope

   **Summary**
   - 3-5 sentence overview of the content
   - Capture the main thrust and purpose

   **Key Points**
   - Bulleted list of the most important items
   - Focus on substance, not structure

   **Issues and Concerns**
   - Anything unclear, missing, or ambiguous
   - Contradictions or logical gaps
   - Potentially problematic statements or claims
   - Areas that need more support or evidence

   **Recommendations**
   - Specific actionable next steps
   - What should be added, clarified, or changed
   - Priority order if there are multiple items

4. **Save the review:**
   - Create filename: `{original-name}-Review-{YYYY-MM-DD}.md`
   - Save in the same directory as the original
   - Use proper markdown formatting

5. **Tell the user:**
   - Confirm the review filename
   - Offer to discuss any specific section in detail
   - Ask if they want you to review any particular aspect more deeply

## Tone

Professional, clear, non-technical. Explain things as you would to a smart colleague who hasn't read the document. Be constructive in criticism and specific in recommendations.
