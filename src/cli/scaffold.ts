// Scaffold — write template files idempotently, create config dirs

import * as fs from "node:fs";
import * as path from "node:path";
import * as os from "node:os";
import { TEMPLATES } from "./templates.js";
import { fileAction } from "./messages.js";

type FileAction = "created" | "unchanged" | "updated";

function writeFileIfChanged(filePath: string, content: string): FileAction {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  if (fs.existsSync(filePath)) {
    const existing = fs.readFileSync(filePath, "utf-8");
    if (existing === content) {
      return "unchanged";
    }
    fs.writeFileSync(filePath, content, "utf-8");
    return "updated";
  }

  fs.writeFileSync(filePath, content, "utf-8");
  return "created";
}

export function scaffoldProject(targetDir: string): void {
  const absTarget = path.resolve(targetDir);

  console.log("");
  console.log(`  Scaffolding project into: ${absTarget}`);
  console.log("");

  for (const [relPath, content] of Object.entries(TEMPLATES)) {
    const fullPath = path.join(absTarget, relPath);
    const action = writeFileIfChanged(fullPath, content);
    console.log(fileAction(relPath, action));
  }

  console.log("");
}

export function ensureApiKeyFile(apiKey: string): void {
  const shingleDir = path.join(os.homedir(), ".shingle");
  const envPath = path.join(shingleDir, "env");

  if (!fs.existsSync(shingleDir)) {
    fs.mkdirSync(shingleDir, { recursive: true });
  }

  // Never overwrite an existing API key file
  if (fs.existsSync(envPath)) {
    const existing = fs.readFileSync(envPath, "utf-8");
    if (existing.includes("ANTHROPIC_API_KEY=")) {
      console.log(`  = ~/.shingle/env (already exists, not overwritten)`);
      return;
    }
  }

  fs.writeFileSync(envPath, `ANTHROPIC_API_KEY=${apiKey}\n`, "utf-8");
  console.log(`  + ~/.shingle/env`);
}

export function ensureClientWorkDir(): void {
  const clientWork = path.join(os.homedir(), "Documents", "ClientWork");

  if (fs.existsSync(clientWork)) {
    console.log(`  = ~/Documents/ClientWork/ (already exists)`);
    return;
  }

  fs.mkdirSync(clientWork, { recursive: true });
  console.log(`  + ~/Documents/ClientWork/`);
}
