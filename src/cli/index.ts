#!/usr/bin/env node

// Shingle CLI — scaffolds the full project for solo consultants

import { BANNER, nextSteps, preflightWarning } from "./messages.js";
import { runPreflightChecks } from "./preflight.js";
import { askApiKey, askPracticeArea } from "./prompts.js";
import { scaffoldProject, ensureApiKeyFile, ensureClientWorkDir } from "./scaffold.js";

function parseArgs(argv: string[]): { command: string; directory: string; practice: string | null } {
  const args = argv.slice(2);
  let command = "";
  let directory = ".";
  let practice: string | null = null;

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--practice" && i + 1 < args.length) {
      practice = args[++i];
    } else if (!command) {
      command = arg;
    } else if (directory === ".") {
      directory = arg;
    }
  }

  return { command, directory, practice };
}

const VALID_PRACTICES = ["legal", "audit", "policy", "govcon", "general"];

async function main(): Promise<void> {
  const { command, directory, practice } = parseArgs(process.argv);

  if (command !== "init") {
    console.log("");
    console.log("  Usage: shingle init [directory] [--practice legal|audit|policy|govcon|general]");
    console.log("");
    console.log("  Scaffolds a Shingle project for solo consultants.");
    console.log("");
    process.exit(command ? 1 : 0);
  }

  if (practice && !VALID_PRACTICES.includes(practice)) {
    console.error(`  Error: Unknown practice area "${practice}".`);
    console.error(`  Valid options: ${VALID_PRACTICES.join(", ")}`);
    process.exit(1);
  }

  // Banner
  console.log(BANNER);

  // Pre-flight checks (warnings only)
  const checks = runPreflightChecks();
  let hasWarnings = false;
  for (const check of checks) {
    if (!check.ok) {
      console.log(preflightWarning(check.name, check.message));
      hasWarnings = true;
    }
  }
  if (hasWarnings) {
    console.log("");
    console.log("  These are warnings — setup will continue anyway.");
    console.log("  You'll need these installed before opening the project.");
    console.log("");
  }

  // API key
  const apiKey = await askApiKey();

  // Practice area
  const selectedPractice = practice ?? (await askPracticeArea());

  // Scaffold project files
  scaffoldProject(directory);

  // Create ~/.shingle/env
  ensureApiKeyFile(apiKey);

  // Create ~/Documents/ClientWork/
  ensureClientWorkDir();

  // Next steps
  console.log(nextSteps(directory, selectedPractice));
}

main().catch((err: unknown) => {
  console.error("");
  console.error("  Something went wrong during setup:");
  console.error(`  ${err instanceof Error ? err.message : String(err)}`);
  console.error("");
  console.error("  If this keeps happening, please open an issue at:");
  console.error("  https://github.com/anthropics/shingle/issues");
  console.error("");
  process.exit(1);
});
