# AGENTS.md

## Overview

Agentpalooza is a plugin marketplace for Claude Code and OpenCode CLI that distributes reusable agents and skills. Users install plugins containing coordinated multi-agent workflows.

## Project Structure

```
agentpalooza/
├── .claude-plugin/
│   └── marketplace.json       # Plugin registry
├── plugins/
│   └── research/
│       ├── .claude-plugin/
│       │   └── plugin.json    # Plugin manifest (Claude Code agents only)
│       ├── claude/agents/     # Claude Code agent definitions
│       ├── opencode/agents/   # OpenCode agent definitions
│       └── README.md
├── AGENTS.md
└── README.md
```

## Plugin Manifests

### marketplace.json (root)

```json
{
  "name": "agentpalooza",
  "version": "1.7.1",
  "metadata": {
    "description": "Plugin marketplace for Claude Code and OpenCode CLI",
    "pluginRoot": "./plugins"
  },
  "owner": { "name": "Shane Maiolo" },
  "plugins": [
    {
      "name": "research",
      "source": "./plugins/research",
      "tags": ["research", "fact-checking", "agents"]
    }
  ]
}
```

### plugin.json (per plugin)

The `agents` field must be an array of individual file paths (not a directory), resolved relative to the plugin root.

```json
{
  "name": "research",
  "version": "1.7.1",
  "description": "Research toolkit with @research-assistant, @research-fact-checker, and @research-report-generator",
  "agents": [
    "./claude/agents/research-assistant.md",
    "./claude/agents/research-fact-checker.md",
    "./claude/agents/research-report-generator.md"
  ]
}
```

OpenCode agents are not registered in plugin.json — they live in `opencode/agents/` and are discovered via subdirectory symlinks. Symlink each plugin's agents directory into `.opencode/agents/agentpalooza-{plugin}` (e.g., `agentpalooza-research`) so they stay namespaced and don't conflict with other agents. See the install script (`scripts/install-opencode.sh`) or README for setup.

## Agent Definition Formats

Each plugin has two sets of agent definitions with identical system prompts but different YAML frontmatter.

### Claude Code (`plugins/{plugin}/claude/agents/`)

```yaml
---
name: agent-name
description: "Description with usage examples"
tools: [Task, Read, Glob, Grep]
model: opus
color: pink
---
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Kebab-case identifier |
| `description` | Yes | Usage description with examples |
| `tools` | Yes | Array: `Task, Read, Write, Edit, Bash, Grep, Glob, WebFetch, WebSearch` |
| `model` | Yes | `opus`, `sonnet`, `haiku`, or `inherit` |
| `color` | Yes | UI color identifier |
| `disallowedTools` | No | Tools to explicitly deny |
| `maxTurns` | No | Max agentic turns |
| `permissionMode` | No | `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan` |
| `memory` | No | `user`, `project`, or `local` |
| `hooks` | No | Lifecycle hooks (PreToolUse, PostToolUse, Stop) |

### OpenCode (`plugins/{plugin}/opencode/agents/`)

```yaml
---
name: agent-name
description: "Description with usage examples"
mode: subagent
maxSteps: 30
tools:
  read: true
  write: false
permission:
  edit: deny
  bash: deny
---
```

Bash permissions accept either a simple string (`allow`, `ask`, `deny`) or an object mapping command patterns to permission levels:

```yaml
permission:
  bash:
    "*": deny
    "mkdir -p .temp": allow
    "mkdir -p .temp/*": allow
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Kebab-case identifier (same as Claude Code counterpart) |
| `description` | Yes | Usage description with examples |
| `mode` | No | `primary`, `subagent`, or `all` |
| `model` | No | Full provider/model string (e.g., `anthropic/claude-opus-4-7`). Omit to use user default. |
| `maxSteps` | No | Max agentic iterations |
| `tools` | No | Object map of tool names to `true`/`false` |
| `temperature` | No | LLM temperature |
| `hidden` | No | Hide from `@` autocomplete |
| `permission` | No | Per-tool rules (`ask`, `allow`, `deny`, or object map of command patterns to permission levels for bash) |

### Cross-CLI Mapping

| Feature | Claude Code | OpenCode |
|---------|------------|----------|
| Tools | `tools: [Read, Write]` | `tools: { read: true, write: true }` |
| Tool denial | `disallowedTools: [Write]` | `write: false` in `tools` |
| Model | `model: opus` | `model: anthropic/claude-opus-4-7` (or omit for default) |
| Turn limit | `maxTurns: 50` | `maxSteps: 50` |
| Path enforcement | `hooks:` (PreToolUse) | System prompt constraints |
| Permissions | `permissionMode: acceptEdits` | `permission:` object per tool |

## Research Plugin

Three agents forming a generate-validate loop with mandatory fact-check certification.

### Agents

| Agent | Role | Claude Code | OpenCode |
|-------|------|-------------|----------|
| `@research-assistant` | Orchestrator — coordinates workflow, manages iteration | opus/pink, hooks enforce `.reports/` writes | primary mode, bash restricted to `.reports/` commands |
| `@research-report-generator` | Generator — produces reports with 2-8 parallel subagents | opus/cyan, maxTurns: 50, hooks enforce `.temp/` writes | subagent mode, maxSteps: 50, bash restricted to `.temp/` commands |
| `@research-fact-checker` | Validator — read-only validation against quality/format rules | sonnet/green, maxTurns: 30, disallowedTools: Write/Edit/Bash/Task, memory: project | subagent mode, maxSteps: 30, write/edit/bash/task disabled, permission deny on edit/bash |

### Workflow

```
User Request → Host CLI asks for Standard Category (1-9) + Report Type
  → @research-assistant (parses config, maps type → quality layer)
    → @research-report-generator → writes draft to .temp/
    → @research-fact-checker → reads draft, returns ACCEPT or REJECT
    → On REJECT: iterate (max 3 attempts)
    → On ACCEPT: move .temp/ → .reports/, deliver to user
```

Reports support 5 quality layers and 9 standard categories. All reports must include: Limitations section, Sources and References, and AI Disclosure.

## Development Guidelines

- Create both `claude/agents/` and `opencode/agents/` versions for every agent
- List each agent file individually in plugin.json `agents` array
- Use identical agent names across CLIs
- Keep system prompt content identical across CLIs; adapt only frontmatter and constraint mechanisms
- OpenCode lacks per-agent hooks — embed path enforcement as system prompt constraints
- Match model to task: Opus for orchestration/generation, Sonnet for validation, Haiku for subagent research
- Set turn/step limits to prevent runaway agents
