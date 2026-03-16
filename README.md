# Agentpalooza

**Version 1.6.0**

A plugin marketplace for Claude Code and OpenCode CLI — distribute reusable agents and skills across projects.

## Supported CLIs

| CLI | Agent Format | Installation |
|-----|-------------|-------------|
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | `.claude-plugin/` manifests + YAML frontmatter agents | `/plugin marketplace add` |
| [OpenCode](https://opencode.ai/) | `.opencode/agents/` markdown files with YAML frontmatter | Copy agent files to project |

## Installation

### Claude Code

**Add the marketplace:**
```
/plugin marketplace add shanemaiolo/agentpalooza
```

**Install a plugin:**
```
/plugin install research@agentpalooza
```

### OpenCode CLI (Symlink)

Clone the repo once and symlink — no need to copy files into every project:

```bash
git clone https://github.com/shanemaiolo/agentpalooza.git ~/agentpalooza
```

**Quick install:**
```bash
./scripts/install-opencode.sh /path/to/your-project

# Or globally:
./scripts/install-opencode.sh --global
```

**Manual setup — per-project:**
```bash
mkdir -p /path/to/your-project/.opencode/agents
ln -s ~/agentpalooza/plugins/research/opencode/agents /path/to/your-project/.opencode/agents/agentpalooza-research
```

**Or globally:**
```bash
mkdir -p ~/.config/opencode/agents
ln -s ~/agentpalooza/plugins/research/opencode/agents ~/.config/opencode/agents/agentpalooza-research
```

This creates a namespaced subdirectory symlink (`agentpalooza-research/`) so plugin agents don't conflict with your own agents or other plugins in `.opencode/agents/`.

Pulling updates (`git pull ~/agentpalooza`) applies everywhere. Use `Tab` to switch to `@research-assistant` or `@mention` subagents in your prompt.

## Available Plugins

| Plugin | Description | Agents | CLIs |
|--------|-------------|--------|------|
| [research](./plugins/research/) | Research toolkit with coordinated agents | @research-assistant, @research-fact-checker, @research-report-generator | Claude Code, OpenCode |

### Research Plugin

A multi-agent research toolkit that coordinates comprehensive research with built-in fact-checking, interactive standard selection, and mandatory certification:

**Claude Code agents** (`plugins/research/claude/agents/`):
- **@research-assistant** — Orchestrates the research workflow, parsing Report Configuration and managing iterations between generation and validation
  - Tools: `Task, Read, Write, Edit, Bash, Grep, Glob`
  - Hooks: PreToolUse on Write enforces `.reports/` path constraint
- **@research-report-generator** — Produces comprehensive research reports using 2-8 parallel subagents, formatted per the selected standard category (1-9) and quality layer (1-5)
  - Tools: `Task, Glob, Grep, Read, Write, WebFetch, WebSearch`
  - Hooks: PreToolUse on Write enforces `.temp/` path constraint
- **@research-fact-checker** — Validates research outputs against quality, format, and standard-specific rules
  - Tools: `Glob, Grep, Read, WebFetch, WebSearch`
  - Safety: `disallowedTools` blocks Write/Edit/Bash/Task; `permissionMode: acceptEdits`

**OpenCode agents** (`plugins/research/opencode/agents/`):
- **@research-assistant** — Same orchestration workflow adapted for OpenCode's agent system
  - Tools: `task, read, write, edit, bash, grep, glob, list`
  - Mode: `primary` | maxSteps: 100 | Model: user default
- **@research-report-generator** — Same research generation with OpenCode tool conventions
  - Tools: `task, read, write, bash, grep, glob, list, webfetch, websearch`
  - Mode: `subagent` | maxSteps: 50 | Model: user default
- **@research-fact-checker** — Same validation logic with OpenCode read-only enforcement
  - Tools: `read, grep, glob, list, webfetch, websearch` (write/edit/bash/task disabled)
  - Mode: `subagent` | maxSteps: 30 | Model: user default

**Interactive selection**: Before research begins, users choose a **Standard Category** (Academic, Industry, Government, Digital, Quality, AI-Report, Use-Case, Custom, or Practical) and a **Report Type** (Quick Brief, Deep Technical, Executive Summary, Compliance, or Hybrid). These selections guide formatting and validation throughout the pipeline.

**Drafts are written to** `.temp/` during generation and validation. After certification, the final report is moved to `.reports/{topic-slug}-{timestamp}.md` for persistent storage.

**Mandatory fact-check certification**: All reports must pass fact-checking validation (including standard-specific checks) before delivery. The fact-checker can ACCEPT (certify and deliver) or REJECT (iterate, max 3 attempts).

```
User Request → Select Standard & Report Type → @research-assistant
                    ↓
         @research-report-generator → [writes draft to .temp/]
                    ↓
         @research-fact-checker ← [reads draft from disk]
                    ↓
         ACCEPT: Certify, move .temp/ → .reports/, Deliver | REJECT: Iterate (max 3x)
```

## Project Configuration

### Claude Code

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "agentpalooza": {
      "source": { "source": "github", "repo": "shanemaiolo/agentpalooza" }
    }
  }
}
```

### OpenCode CLI

No project-level configuration is required beyond symlinking (or copying) agent files to `.opencode/agents/`. OpenCode automatically discovers agent markdown files in that directory.

To verify agents are loaded:
```bash
opencode agents
```

## Adding New Plugins

### 1. Create Plugin Structure

```
plugins/
└── your-plugin/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── claude/
    │   └── agents/               # Claude Code agents
    │       └── your-agent.md
    ├── opencode/
    │   └── agents/               # OpenCode agents
    │       └── your-agent.md
    └── README.md
```

### 2. Create Plugin Manifest

Create `.claude-plugin/plugin.json`:

```json
{
  "name": "your-plugin",
  "version": "1.0.0",
  "description": "Your plugin description",
  "agents": [
    "./claude/agents/your-agent.md",
    "./claude/agents/another-agent.md"
  ],
  "opencode": {
    "agents": [
      "./opencode/agents/your-agent.md",
      "./opencode/agents/another-agent.md"
    ]
  }
}
```

**Important**: The `agents` field must be an array of individual file paths, not a directory. Paths are resolved relative to the plugin root (the directory containing `.claude-plugin/`).

### 3. Define Agents

#### Claude Code Format

```yaml
---
name: your-agent
description: "Agent description with usage examples"
tools: [Task, Read, Glob, Grep, WebSearch]
model: opus
color: cyan
---

[System prompt and operational guidelines]
```

**Required fields:** `name`, `description`, `tools` (array), `model` (opus/sonnet/haiku), `color`

**Optional fields:** `maxTurns`, `disallowedTools`, `permissionMode`, `memory`, `hooks`

#### OpenCode Format

```yaml
---
name: your-agent
description: "Agent description with usage examples"
mode: subagent
model: anthropic/claude-sonnet-4
maxSteps: 30
tools:
  read: true
  write: true
  edit: true
  bash: true
  grep: true
  glob: true
  task: true
  webfetch: false
  websearch: false
---

[System prompt and operational guidelines]
```

**Required fields:** `name`, `description`

**Optional fields:** `mode` (primary/subagent/all), `model` (provider/model string), `maxSteps`, `tools` (object), `temperature`, `hidden`, `permission`

#### Key Differences Between Formats

| Feature | Claude Code | OpenCode |
|---------|------------|----------|
| Tool format | Array: `[Task, Read, Write]` | Object: `task: true, read: true` |
| Model names | `opus`, `sonnet`, `haiku` | `anthropic/claude-opus-4`, etc. |
| Turn limits | `maxTurns: 50` | `maxSteps: 50` |
| Tool denial | `disallowedTools: [Write, Edit]` | `write: false, edit: false` in tools |
| Agent mode | Implicit (based on usage) | Explicit: `mode: primary\|subagent` |
| Hooks | `hooks:` YAML block (PreToolUse, etc.) | Not supported per-agent; use system prompt constraints |
| UI color | `color: cyan` | Not supported |
| Memory | `memory: project` | Not supported natively |

### 4. Register in Marketplace

Update `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "your-plugin",
      "description": "Your plugin description",
      "source": "./plugins/your-plugin",
      "tags": ["your", "tags"],
      "supportedCLIs": ["claude-code", "opencode"]
    }
  ]
}
```

## Project Structure

```
agentpalooza/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace catalog
├── plugins/
│   └── research/              # Research plugin
│       ├── .claude-plugin/
│       │   └── plugin.json    # Plugin manifest
│       ├── claude/
│       │   └── agents/        # Claude Code agents
│       │       ├── research-assistant.md
│       │       ├── research-fact-checker.md
│       │       └── research-report-generator.md
│       ├── opencode/
│       │   └── agents/        # OpenCode agents
│       │       ├── research-assistant.md
│       │       ├── research-fact-checker.md
│       │       └── research-report-generator.md
│       └── README.md
├── AGENTS.md                  # Development guide
├── README.md
└── LICENSE
```

## License

Apache 2.0
