# Agentpalooza

**Version 1.2.1**

A plugin marketplace for Claude Code — distribute reusable agents and skills across projects.

## Installation

**Add the marketplace:**
```
/plugin marketplace add shanemaiolo/agentpalooza
```

**Install a plugin:**
```
/plugin install research@agentpalooza
```

## Available Plugins

| Plugin | Description | Agents |
|--------|-------------|--------|
| [research](./plugins/research/) | Research toolkit with coordinated agents | @research-assistant, @research-fact-checker, @research-report-generator |

### Research Plugin

A multi-agent research toolkit that coordinates comprehensive research with built-in fact-checking, interactive standard selection, and mandatory certification:

- **@research-assistant** — Orchestrates the research workflow, parsing Report Configuration and managing iterations between generation and validation
  - Tools: `Task, Read, Write, Edit, Grep, Glob`
- **@research-report-generator** — Produces comprehensive research reports using 2-8 parallel subagents, formatted per the selected standard category (1-9) and quality layer (1-5)
  - Tools: `Task, Glob, Grep, Read, Write, WebFetch, WebSearch`
- **@research-fact-checker** — Validates research outputs against quality, format, and standard-specific rules
  - Tools: `Glob, Grep, Read, WebFetch, WebSearch`

**Interactive selection**: Before research begins, users choose a **Standard Category** (Academic, Industry, Government, Digital, Quality, AI-Report, Use-Case, Custom, or Practical) and a **Report Type** (Quick Brief, Deep Technical, Executive Summary, Compliance, or Hybrid). These selections guide formatting and validation throughout the pipeline.

**Reports are saved to** `.reports/{topic-slug}-{timestamp}.md` for persistent storage and cross-agent access.

**Mandatory fact-check certification**: All reports must pass fact-checking validation (including standard-specific checks) before delivery. The fact-checker can ACCEPT (certify and deliver) or REJECT (iterate, max 3 attempts).

```
User Request → Select Standard & Report Type → @research-assistant
                    ↓
         @research-report-generator → [writes to .reports/]
                    ↓
         @research-fact-checker ← [reads from disk]
                    ↓
         ACCEPT: Certify & Deliver | REJECT: Iterate (max 3x)
```

## Project Configuration

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

## Adding New Plugins

### 1. Create Plugin Structure

```
plugins/
└── your-plugin/
    ├── .claude-plugin/
    │   └── plugin.json
    ├── agents/
    │   └── your-agent.md
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
    "./agents/your-agent.md",
    "./agents/another-agent.md"
  ]
}
```

**Important**: The `agents` field must be an array of individual file paths, not a directory. Paths are resolved relative to the plugin root (the directory containing `.claude-plugin/`).

### 3. Define Agents

Create agent files as markdown with YAML frontmatter:

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

**Required fields:**
- `name` — Agent identifier (kebab-case)
- `description` — Usage description
- `tools` — Array of available tools
- `model` — Claude model (e.g., "opus", "sonnet")
- `color` — UI color identifier

### 4. Register in Marketplace

Update `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "your-plugin",
      "description": "Your plugin description",
      "source": "./plugins/your-plugin",
      "tags": ["your", "tags"]
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
│       ├── agents/
│       │   ├── research-assistant.md
│       │   ├── research-fact-checker.md
│       │   └── research-report-generator.md
│       └── README.md
├── AGENTS.md                  # Development guide
├── README.md
└── LICENSE
```

## License

MIT
