# Two-Phase Bootstrap Redesign

## Summary

This redesign replaces the current `npx shingle init` CLI with a two-phase conversational bootstrap. Phase 1 runs Claude Code on the user's bare host machine to install prerequisites (Docker, VS Code, Dev Containers extension), configure the API key, create the working directory structure, and capture the user's practice area choice. Phase 2 runs Claude Code inside a firewalled devcontainer where actual consulting work happens — Claude has access to a pre-installed tech stack (Node.js, Python, pandoc) and can build tools like spreadsheet analyzers, document converters, or single-file web apps while being network-isolated from everything except the Anthropic API and a few allowlisted data sources.

The bootstrap flow becomes: user runs one PowerShell/shell command, Claude Code installs itself and walks the user through setup conversationally, explaining each step. The user opens VS Code and clicks "Reopen in Container," and containerized Claude loads practice-area-specific instructions. The entire CLI codebase (`src/cli/`, TypeScript build pipeline, npm packaging) is eliminated in favor of a Phase 1 CLAUDE.md that tells Claude how to perform those setup actions interactively. This trades programmatic automation for conversational guidance, making the onboarding process more transparent and adaptable to edge cases (missing prerequisites, failed installations, Windows-specific quirks).

## Definition of Done

1. **A bootstrap script** (PowerShell for Windows, shell script for Mac) that installs Claude Code, sets the API key, and starts a Claude session with setup instructions baked in
2. **Phase 1 setup instructions** (CLAUDE.md or system prompt) that tell host-mode Claude how to install Docker, VS Code, Dev Containers extension, scaffold the Shingle project, and create the ClientWork folder
3. **Updated devcontainer** with Python and pandoc added to the image alongside Node.js/TypeScript
4. **Updated CLAUDE.md templates** with a tech stack recommendation section — TypeScript for web tools/automation, Python for data analysis, Markdown+pandoc for documents
5. **Practice-area selection happens once** — either during Phase 1 or on first container attach, not both
6. **The `npx shingle init` CLI is removed** — its scaffolding logic is repurposed into the Phase 1 instructions
7. **Updated docs** (QUICKSTART.md) reflecting the new "one command" bootstrap flow

## Glossary

- **Bootstrap script**: A PowerShell (Windows) or shell (Mac) script that installs Claude Code, creates the project directory structure, and launches Claude for the first time. The entry point for the entire setup process.
- **Devcontainer**: A Docker-based development environment specification (part of VS Code's Dev Containers extension) that defines the isolated sandbox where Phase 2 Claude runs. Includes the container image, bind mounts, startup commands, and security settings.
- **Phase 1 CLAUDE.md**: A project-root markdown file containing setup instructions that host-mode Claude follows to install prerequisites, configure the environment, and hand off to Phase 2. Becomes inert once the user enters the container.
- **Phase 2 CLAUDE.md**: The containerized CLAUDE.md assembled by `welcome.sh` from `CLAUDE.md.base` and a practice-area overlay. Tells Claude how to build tools for consulting work using the pre-installed tech stack.
- **Practice area**: One of five specializations (legal, audit, policy, govcon, general) that determines which overlay gets appended to the base CLAUDE.md. Selected during Phase 1 and stored in `.shingle-config`.
- **`.shingle-config`**: A plain text file written during Phase 1 containing the user's practice area choice. Read by `welcome.sh` to determine which CLAUDE.md overlay to use.
- **`welcome.sh`**: A script run by `postAttachCommand` when the user first attaches to the container. Reads `.shingle-config`, assembles the Phase 2 CLAUDE.md, installs the Claude Code plugin, and displays a welcome banner.
- **`init-firewall.sh`**: A startup script (run by `postStartCommand`) that configures iptables rules to block all outbound network traffic except allowlisted hosts.
- **Bind mount**: A mechanism for mapping a host directory into a container. Shingle uses bind mounts for `~/.shingle/env` (API key, read-only) and `~/Documents/ClientWork/` (client files, read-write).
- **MCP server**: Model Context Protocol server — a background process that provides Claude with callable tools. Shingle includes a Federal Register MCP server for legal/policy work.
- **pandoc**: A command-line document converter. Claude uses it to transform Markdown into PDF, DOCX, or HTML for polished deliverables.
- **Static single-file HTML**: An HTML file with inline CSS and JavaScript, no external dependencies. Default output format for web tools — consultant opens it directly in a browser.
- **`chart.js`**: A JavaScript charting library pre-installed in the container. Claude copies it into static HTML files to create interactive visualizations.
- **`vite`**: A development server for modern web apps. Pre-installed but only used for rare cases needing multi-page apps or real-time data.
- **Python data stack**: Pre-installed Python packages for data analysis — `pandas` (data manipulation), `matplotlib` (charts), `openpyxl` (Excel reading), `xlsxwriter` (Excel writing).
- **`winget`**: Windows Package Manager, a CLI tool for installing software. Phase 1 Claude uses it to install Docker Desktop and VS Code.
- **Guardrails**: Safety rules embedded in the Phase 1 CLAUDE.md that prevent Claude from performing destructive or out-of-scope actions during setup.

## Architecture

Shingle's onboarding becomes a two-phase pipeline: Phase 1 runs Claude Code on the bare host to install prerequisites and configure the environment. Phase 2 runs Claude Code inside a firewalled devcontainer for actual consulting work.

### Phase 1: Host Bootstrap

A single PowerShell command (Windows) or shell command (Mac) installs Claude Code via its native installer — no Node.js, no npm. The script then creates `~/Documents/Shingle/` containing the full project (`.devcontainer/`, `plugin/`, `templates/`, `docs/`) and a Phase 1 `CLAUDE.md` with host setup instructions.

When Claude launches in that directory, it reads the Phase 1 CLAUDE.md and walks the user through:

1. Checking what's already installed (Docker, VS Code, Dev Containers extension)
2. Installing missing prerequisites via `winget` (Windows) or `brew`/direct download (Mac)
3. Setting up the API key in `~/.shingle/env`
4. Creating `~/Documents/ClientWork/`
5. Asking "What kind of work do you do?" to select a practice area, writing the choice to `.shingle-config`
6. Telling the user to open VS Code and "Reopen in Container"

Phase 1 Claude operates with full host access but follows strict guardrails in the CLAUDE.md: only install listed software, explain every action before doing it, never modify system settings beyond what's needed, and if something fails, explain clearly without retrying destructively.

### Phase 2: Container Sandbox

Once the user reopens in the container, the devcontainer takes over:

- `postStartCommand` runs `init-firewall.sh` — blocks all outbound except Anthropic API, npm registry, Federal Register, and DNS
- `postAttachCommand` runs `welcome.sh` — reads `.shingle-config`, assembles the Phase 2 CLAUDE.md (base + practice area overlay), installs the plugin, shows the welcome banner
- User types `claude` and gets the sandboxed experience with `/review`, `/summarize`, `/draft`, `/help-me`, and the Federal Register MCP server

### Phase Transition

The Phase 1 CLAUDE.md sits at the project root (`~/Documents/Shingle/CLAUDE.md`). The Phase 2 CLAUDE.md is assembled by `welcome.sh` into `/workspace/documents/CLAUDE.md`. Since the container's `WORKDIR` is `/workspace/documents/`, Claude's directory walk finds Phase 2 first. Phase 1 becomes inert inside the container.

If the user accidentally runs `claude` on the host after setup, Phase 1 Claude detects everything is already installed and directs them to open VS Code instead.

### Data Flow Between Phases

Only one artifact flows from Phase 1 to Phase 2: `.shingle-config`, a plain text file containing the practice area choice (`legal`, `audit`, `policy`, `govcon`, or `general`). The API key flows via the `~/.shingle/env` bind mount (read-only inside the container).

### Container Security

**Network:** Firewall blocks all outbound except allowlisted hosts. No PyPI — all packages pre-installed.

**Isolation:** No Docker socket mount. No privileged mode. Container runs as `node` user with sudo limited to `iptables`, `ipset`, `ip`, and `init-firewall.sh`.

**File safety:** A Claude Code hook blocks creation of host-executable file types (`.bat`, `.ps1`, `.exe`, `.cmd`, `.vbs`) in the bind-mounted `/workspace/documents/` directory. HTML with inline JS is permitted (runs in browser sandbox).

**Credentials:** API key mounted read-only from host. Cannot be modified from inside the container.

### Tech Stack Inside the Container

The devcontainer image pre-installs everything Claude needs to build tools for consultants:

**Documents:** Markdown as the primary format. `pandoc` converts to PDF, DOCX, or HTML for polished deliverables. `poppler-utils` for PDF text extraction.

**Web tools:** Static single-file HTML with inline CSS/JS is the default output. Consultant opens the file directly from their ClientWork folder — no server, no build step, no explanation needed. For charts and visualization, `chart.js` is pre-installed as an npm package that Claude copies into the HTML. `vite` is available for rare cases needing a dev server (multi-page apps, real-time data).

**Data analysis:** Python 3 with `pandas`, `matplotlib`, `openpyxl`, and `xlsxwriter`. Claude writes Python scripts that process CSV/Excel input and produce output files (Excel workbooks, PNG/PDF charts, Markdown reports). All output goes to `/workspace/documents/`.

**CLAUDE.md template guidance:** The base template includes a "Building Tools" section that tells Claude which stack to use for which output type, and how to communicate about it in plain language ("I've created a tracking spreadsheet for you" not "I wrote a Python script").

## Existing Patterns

The current Shingle codebase has established patterns that this design preserves:

**Plugin structure:** `plugin/.claude-plugin/plugin.json` manifest, skills in `plugin/skills/{name}/SKILL.md`, MCP servers in `plugin/servers/{name}/`. Unchanged by this redesign.

**Template system:** `templates/CLAUDE.md.base` as shared foundation, practice-area overlays appended at first run. The assembly mechanism in `welcome.sh` is preserved — only the trigger changes (reads `.shingle-config` instead of prompting interactively).

**Firewall pattern:** `init-firewall.sh` resolves hosts via `dig` and adds iptables rules. New hosts (if any) follow the same pattern.

**Devcontainer conventions:** `postStartCommand` for system setup (firewall), `postAttachCommand` for user setup (welcome, plugin install). Preserved.

**Divergence from existing patterns:**

- The `npx shingle init` CLI (`src/cli/`) is removed entirely. Its logic (practice area selection, API key management, project scaffolding) is repurposed as instructions in the Phase 1 CLAUDE.md — Claude performs these actions conversationally instead of a TypeScript program doing them programmatically.
- The `templates.ts` embedded template copies are eliminated. Templates live only on disk in `templates/` and are copied into the container image at build time.

## Implementation Phases

### Phase 1: Create Bootstrap Scripts
**Goal:** PowerShell (Windows) and shell (Mac) scripts that install Claude Code and scaffold the project directory.

**Components:**
- `bootstrap/setup.ps1` — Windows bootstrap (~30 lines): install Claude Code via native installer, fix PATH, clone/download project to `~/Documents/Shingle/`, launch `claude`
- `bootstrap/setup.sh` — Mac bootstrap: same logic with shell equivalents (`curl | bash` for Claude Code, `git clone` or `curl`+`unzip` for project)

**Dependencies:** None (first phase)

**Done when:** Running the script on a clean machine installs Claude Code, creates the project directory with all files, and launches Claude in that directory.

### Phase 2: Write Phase 1 CLAUDE.md
**Goal:** Setup instructions that host-mode Claude follows to install prerequisites and configure the environment.

**Components:**
- `CLAUDE.md` at project root — Phase 1 setup instructions covering: greeting/introduction, prerequisite detection and installation (Docker, VS Code, Dev Containers), API key setup, ClientWork folder creation, practice area selection (writes `.shingle-config`), handoff instructions
- Guardrails section: only install listed software, explain actions, no destructive retries, no system modification beyond what's needed

**Dependencies:** Phase 1 (bootstrap scripts create the directory where this file lives)

**Done when:** Claude Code launched in the project directory reads the CLAUDE.md and can walk through the full setup flow on a clean Windows machine. All prerequisites get installed, API key gets saved, practice area gets recorded.

### Phase 3: Update Devcontainer Image
**Goal:** Add Python data stack and pandoc to the container image.

**Components:**
- `.devcontainer/Dockerfile` — add `python3`, `python3-pip`, `pandoc` via apt; pre-install Python packages (`pandas`, `matplotlib`, `openpyxl`, `xlsxwriter`) via pip; pre-install npm packages (`chart.js`, `vite`) globally or in a shared location
- `.devcontainer/devcontainer.json` — fix `${localEnv:HOME}` to work reliably on Windows (use `${localEnv:USERPROFILE}` with fallback)

**Dependencies:** None (can run in parallel with Phases 1-2)

**Done when:** Container builds successfully, `python3 -c "import pandas, matplotlib, openpyxl"` succeeds, `pandoc --version` succeeds, `node -e "require('chart.js')"` succeeds inside the container.

### Phase 4: Add Executable File Hook
**Goal:** Block creation of host-executable file types in the documents directory.

**Components:**
- Claude Code hook (in `plugin/hooks/`) that intercepts file writes to `/workspace/documents/` and rejects `.bat`, `.ps1`, `.exe`, `.cmd`, `.vbs` extensions
- Hook logs the rejection and tells Claude to use a safe format

**Dependencies:** Phase 3 (devcontainer must be buildable)

**Done when:** Attempting to write a `.bat` file to `/workspace/documents/` is blocked with a clear message. Writing `.html`, `.md`, `.py`, `.xlsx` files works normally.

### Phase 5: Update CLAUDE.md Templates
**Goal:** Add tech stack guidance to the base template.

**Components:**
- `templates/CLAUDE.md.base` — new "Building Tools" section: when to use Markdown+pandoc (documents), static HTML (web tools), Python (data analysis); communication rules for tool-building ("I've created a tracking spreadsheet" not "I wrote a Python script"); guidance on dev server usage (rare, explain with "click the blue link")
- `welcome.sh` — modify to read `.shingle-config` instead of prompting for practice area; keep plugin install and CLAUDE.md assembly logic

**Dependencies:** Phase 3 (templates reference tools that must be installed)

**Done when:** Container starts, reads `.shingle-config`, assembles CLAUDE.md with tech stack section, and Phase 2 Claude knows how to build tools using the recommended stack.

### Phase 6: Remove CLI and Update Docs
**Goal:** Remove the `npx shingle init` CLI and rewrite documentation for the new flow.

**Components:**
- Delete `src/cli/` directory (all `.ts` and `.test.ts` files)
- Remove CLI-related entries from `package.json` (bin, build scripts, tsup config, test scripts)
- Remove `tsup` and related dev dependencies
- Rewrite `docs/QUICKSTART.md` — new flow: one command → Claude walks you through setup → open VS Code
- Rewrite `docs/FIRST-SESSION.md` — update to reflect new onboarding experience
- Update project `CLAUDE.md` to reflect new architecture (no CLI, bootstrap scripts instead)

**Dependencies:** Phases 1-5 (new flow must work before removing old one)

**Done when:** `src/cli/` is gone, no build step exists, docs accurately describe the bootstrap → Phase 1 → Phase 2 flow.

## Additional Considerations

**Windows `${localEnv:HOME}` issue:** The current `devcontainer.json` uses `${localEnv:HOME}` for bind mounts. On Windows, `HOME` is often unset — `USERPROFILE` is the correct variable. Phase 3 fixes this. If neither is set (unusual), the container fails to start with a clear error rather than silently mounting empty directories.

**Docker Desktop reboot requirement:** First-time Docker Desktop installation on Windows requires a reboot to enable Hyper-V/WSL2. Phase 1 Claude needs to handle this gracefully — tell the user to reboot, and when they re-run the bootstrap or re-launch Claude, it picks up where it left off (detects Docker is now installed, skips to the next step).

**winget first-run quirks:** Fresh Windows machines may need `--accept-source-agreements --accept-package-agreements` flags, and in rare cases winget itself needs registration (`Add-AppxPackage -RegisterByFamilyName`). The Phase 1 CLAUDE.md should include fallback instructions for these scenarios.
