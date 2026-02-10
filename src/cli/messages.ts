// User-facing copy — banner, next steps, warnings

export const BANNER = `
  ┌──────────────────────────────────────────┐
  │             Shingle Setup                │
  │   Claude Code for solo consultants       │
  └──────────────────────────────────────────┘
`;

export function nextSteps(targetDir: string, practice: string): string {
  return `
  All set! Here's what to do next:

  1. Make sure Docker Desktop is running
  2. Open VS Code
  3. File > Open Folder > ${targetDir}
  4. Click "Reopen in Container" when prompted
  5. Type "claude" in the terminal

  Your practice area: ${practice}
  Your documents folder: ~/Documents/ClientWork/

  For a guided walkthrough, see:
    ${targetDir}/docs/FIRST-SESSION.md
`;
}

export function preflightWarning(name: string, message: string): string {
  return `  [!] ${name}: ${message}`;
}

export function fileAction(path: string, action: "created" | "unchanged" | "updated"): string {
  return `  ${actionSymbol(action)} ${path}`;
}

function actionSymbol(action: "created" | "unchanged" | "updated"): string {
  switch (action) {
    case "created":
      return "+";
    case "updated":
      return "~";
    case "unchanged":
      return "=";
  }
}
