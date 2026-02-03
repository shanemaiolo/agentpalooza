# AGENTS.md - Agentpalooza Project Guide

## Project Overview

Agentpalooza is a plugin marketplace for Claude Code that distributes reusable agents and skills across projects. Users can add the marketplace to their Claude Code environment and install individual plugins containing coordinated multi-agent workflows.

## Project Structure

```
agentpalooza/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace catalog and plugin registry
├── .claude/
│   └── settings.local.json    # Local configuration with permission rules
├── plugins/
│   └── research/              # Research toolkit plugin
│       ├── .claude-plugin/
│       │   └── plugin.json    # Plugin manifest
│       ├── agents/
│       │   ├── research-assistant.md
│       │   ├── research-fact-checker.md
│       │   └── research-report-generator.md
│       └── README.md
├── README.md
├── AGENTS.md
└── LICENSE
```

## Plugin Architecture

### Plugin Manifest (`plugin.json`)

Each plugin requires a `.claude-plugin/plugin.json` manifest:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Plugin description",
  "agents": [
    "./agents/agent-name.md"
  ]
}
```

**Critical**: The `agents` field must be an **array of individual file paths**, not a directory path. Paths are resolved relative to the plugin root (the directory containing `.claude-plugin/`).

### Marketplace Registry (`marketplace.json`)

The root marketplace catalog lists all available plugins:

```json
{
  "name": "agentpalooza",
  "version": "1.0.0",
  "metadata": {
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "research",
      "source": "./plugins/research",
      "tags": ["research", "fact-checking", "agents"]
    }
  ]
}
```

## Agent Definition Format

Agents are defined as markdown files with YAML frontmatter:

```yaml
---
name: agent-name
description: "Description with usage examples"
tools: [Task, Read, Glob, Grep]
model: opus
color: pink
---

[System prompt and operational guidelines in markdown]
```

**Required Fields**:
- `name`: Agent identifier (kebab-case)
- `description`: Usage description with examples
- `tools`: Array of available tools
- `model`: Claude model (e.g., "opus")
- `color`: UI color identifier

## Research Plugin Agents

### @research-assistant (Orchestrator)
- **Role**: Coordinates research workflow between generation and validation
- **Model**: Opus | **Color**: Pink
- **Workflow**: Manages iterative verification cycles (max 3 attempts)

### @research-report-generator (Generator)
- **Role**: Produces comprehensive research reports using parallel subagents
- **Model**: Opus | **Color**: Cyan
- **Spawns**: 2-8 specialized subagents for parallel research

### @research-fact-checker (Validator)
- **Role**: Validates research outputs against quality and format standards
- **Model**: Opus | **Color**: Green
- **Output**: ACCEPT or REJECT with required actions

### Agent Interaction Flow

```
User Request
     │
     ▼
@research-assistant
     │
     ├──► @research-report-generator
     │         │
     │         ├──► Spawn subagents (2-8)
     │         │
     │         ▼
     │    Research Report
     │         │
     ▼         ▼
@research-fact-checker
     │
     ├── ACCEPT ──► Deliver Report
     │
     └── REJECT ──► Required Actions (iterate up to 3x)
```

## Key Findings and Lessons Learned

### Plugin Manifest Schema Requirements

1. **agents field**: Must be an array of file paths, not a directory
   - Invalid: `"agents": "./agents"`
   - Valid: `"agents": ["./agents/agent.md"]`

2. **Path resolution**: Agent paths resolve from the plugin root (directory containing `.claude-plugin/`)

3. **File paths**: Each agent must be explicitly listed as a separate array element

### Naming Conventions

- Plugin names: kebab-case (`research`)
- Agent names: kebab-case with domain prefix (`research-assistant`)
- Agent references: Use `@` prefix (`@research-assistant`)

### Tool Assignment Strategy

Different agents should receive tools appropriate to their responsibilities:
- **Orchestrators**: Task management, file reading, searching
- **Generators**: Research tools (WebFetch, WebSearch, Task), writing, editing
- **Validators**: Analysis tools (Grep, Read, Glob), quality assessment

## Development Guidelines

1. **Plugin Structure**: Always include `.claude-plugin/plugin.json` in the plugin directory
2. **Agent Files**: Place agent `.md` files in an `agents/` subdirectory
3. **Explicit Paths**: List each agent file individually in the manifest
4. **Documentation**: Include README.md explaining workflow and usage
5. **Examples**: Agent descriptions should include usage examples with commentary

## Permissions

Local settings (`.claude/settings.local.json`) control tool access:
```json
{
  "permissions": {
    "allow": ["Bash(git add:*)", "Bash(git commit:*)"]
  }
}
```
