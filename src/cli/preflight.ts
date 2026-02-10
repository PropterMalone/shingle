// Pre-flight checks — Docker, VS Code

import { execSync } from "node:child_process";

export interface CheckResult {
  name: string;
  ok: boolean;
  message: string;
}

function checkCommand(command: string): boolean {
  try {
    execSync(command, { stdio: "pipe" });
    return true;
  } catch {
    return false;
  }
}

export function runPreflightChecks(): CheckResult[] {
  const results: CheckResult[] = [];

  // Docker
  const dockerOk = checkCommand("docker --version");
  results.push({
    name: "Docker",
    ok: dockerOk,
    message: dockerOk
      ? "Docker is installed"
      : "Docker not found. Install from https://www.docker.com/products/docker-desktop/",
  });

  // VS Code
  const codeOk = checkCommand("code --version");
  results.push({
    name: "VS Code",
    ok: codeOk,
    message: codeOk
      ? "VS Code is installed"
      : "VS Code not found. Install from https://code.visualstudio.com/",
  });

  return results;
}
