import { describe, it, expect, beforeEach, afterEach } from "vitest";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { writeFileIfChanged, scaffoldProject } from "./scaffold.js";
import { TEMPLATES } from "./templates.js";

let tmpDir: string;

beforeEach(() => {
  tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "shingle-test-"));
});

afterEach(() => {
  fs.rmSync(tmpDir, { recursive: true, force: true });
});

describe("writeFileIfChanged", () => {
  it("creates file in new directory and returns 'created'", () => {
    const filePath = path.join(tmpDir, "sub", "dir", "file.txt");
    const result = writeFileIfChanged(filePath, "hello");
    expect(result).toBe("created");
    expect(fs.readFileSync(filePath, "utf-8")).toBe("hello");
  });

  it("returns 'unchanged' when content matches", () => {
    const filePath = path.join(tmpDir, "file.txt");
    fs.writeFileSync(filePath, "hello", "utf-8");
    const result = writeFileIfChanged(filePath, "hello");
    expect(result).toBe("unchanged");
  });

  it("returns 'updated' when content differs", () => {
    const filePath = path.join(tmpDir, "file.txt");
    fs.writeFileSync(filePath, "hello", "utf-8");
    const result = writeFileIfChanged(filePath, "goodbye");
    expect(result).toBe("updated");
    expect(fs.readFileSync(filePath, "utf-8")).toBe("goodbye");
  });
});

describe("scaffoldProject", () => {
  it("writes all TEMPLATES keys", () => {
    scaffoldProject(tmpDir);
    const expectedKeys = Object.keys(TEMPLATES);
    for (const key of expectedKeys) {
      const filePath = path.join(tmpDir, key);
      expect(fs.existsSync(filePath), `expected ${key} to exist`).toBe(true);
    }
  });

  it("is idempotent — second run produces all unchanged", () => {
    scaffoldProject(tmpDir);

    // Capture console output on second run to verify no "created" or "updated"
    const logs: string[] = [];
    const origLog = console.log;
    console.log = (...args: unknown[]) => logs.push(args.join(" "));
    scaffoldProject(tmpDir);
    console.log = origLog;

    // Every file action line should show "=" (unchanged)
    const actionLines = logs.filter((l) => l.includes("  + ") || l.includes("  ~ ") || l.includes("  = "));
    for (const line of actionLines) {
      expect(line).toContain("=");
    }
  });
});
