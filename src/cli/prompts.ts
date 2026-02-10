// Interactive prompts — API key, practice area

import * as readline from "node:readline";
import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";

function ask(question: string): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

export function checkExistingApiKey(): string | null {
  const envPath = path.join(os.homedir(), ".shingle", "env");
  if (!fs.existsSync(envPath)) return null;

  const content = fs.readFileSync(envPath, "utf-8");
  const match = content.match(/^ANTHROPIC_API_KEY=(.+)$/m);
  if (match && match[1].startsWith("sk-ant-")) {
    return match[1];
  }
  return null;
}

export async function askApiKey(): Promise<string> {
  const existing = checkExistingApiKey();
  if (existing) {
    const masked = existing.slice(0, 10) + "..." + existing.slice(-4);
    console.log(`  Found existing API key: ${masked}`);
    const reuse = await ask("  Use this key? (Y/n) ");
    if (reuse.toLowerCase() !== "n") {
      return existing;
    }
  }

  console.log("");
  console.log("  You need an Anthropic API key to use Shingle.");
  console.log("  Get one at: https://console.anthropic.com/");
  console.log("");

  while (true) {
    const key = await ask("  Paste your API key: ");
    if (key.startsWith("sk-ant-")) {
      return key;
    }
    console.log("  That doesn't look right — API keys start with sk-ant-");
  }
}

const PRACTICE_MENU = `
  What kind of consulting do you do?

    1) Legal (attorney, regulatory counsel)
    2) Audit (auditor, investigator, IG)
    3) Policy (policy analyst, legislative affairs)
    4) GovCon (procurement, contracts, proposals)
    5) General (skip practice-specific setup)
`;

const CHOICE_MAP: Record<string, string> = {
  "1": "legal",
  "2": "audit",
  "3": "policy",
  "4": "govcon",
  "5": "general",
};

export async function askPracticeArea(): Promise<string> {
  console.log(PRACTICE_MENU);

  while (true) {
    const choice = await ask("  Enter 1-5: ");
    const area = CHOICE_MAP[choice];
    if (area) return area;
    console.log("  Please enter a number from 1 to 5.");
  }
}
