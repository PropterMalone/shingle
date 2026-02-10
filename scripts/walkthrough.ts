// Manual walkthrough — scaffolds a temp project so you can inspect the full new-user output.
// Run with: npm run walkthrough

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import * as readline from "node:readline";
import { scaffoldProject } from "../src/cli/scaffold.js";

const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "shingle-walkthrough-"));

console.log("");
console.log("  Shingle Walkthrough");
console.log("  ===================");
console.log("");
console.log(`  Scaffolding into: ${tmpDir}`);
console.log("");

scaffoldProject(tmpDir);

// List all created files with sizes
const files: Array<{ rel: string; size: number }> = [];

function walk(dir: string, base: string): void {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    const rel = path.join(base, entry.name);
    if (entry.isDirectory()) {
      walk(full, rel);
    } else {
      files.push({ rel, size: fs.statSync(full).size });
    }
  }
}

walk(tmpDir, "");

console.log(`  ${files.length} files created:\n`);
for (const f of files) {
  const sizeStr = f.size >= 1024 ? `${(f.size / 1024).toFixed(1)} KB` : `${f.size} B`;
  console.log(`    ${sizeStr.padStart(10)}  ${f.rel}`);
}

console.log("");
console.log(`  Inspect the output at: ${tmpDir}`);
console.log("");

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
rl.question("  Press Enter to clean up and exit...", () => {
  fs.rmSync(tmpDir, { recursive: true, force: true });
  console.log("  Cleaned up.");
  rl.close();
});
