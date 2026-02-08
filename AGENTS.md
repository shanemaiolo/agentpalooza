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
  "version": "1.1.0",
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
- **Tools**: `Task, Read, Write, Edit, Grep, Glob`
- **Workflow**: Parses the Report Configuration block (Standard Category + Report Type), maps Report Type to Quality Layer, then manages iterative verification cycles (max 3 attempts)
- **Pre-spawn Requirement**: The main Claude instance must ask the user for Standard Category (1-9) and Report Type via `AskUserQuestion` before launching this agent, prepending selections as a `**Report Configuration**` block

### @research-report-generator (Generator)
- **Role**: Produces comprehensive research reports using parallel subagents
- **Model**: Opus | **Color**: Cyan
- **Tools**: `Task, Glob, Grep, Read, Write, WebFetch, WebSearch`
- **Spawns**: 2-8 specialized subagents for parallel research
- **Output**: Writes reports to `.reports/{topic-slug}-{timestamp}.md`
- **Quality Layers**: Supports 5 report quality layers (Layer 1 Base through Layer 5 Publication-Ready). All reports at every layer must include: Limitations section, Sources and References, and AI Disclosure.
- **Standard Categories**: Supports 9 report standards (Academic, Industry/Professional, Government/Institutional, Digital/Web, Quality Criteria, AI-Report Standards, Use-Case Optimized, Custom/Hybrid, Practical/System-Aligned) that govern formatting and structure independently from quality layers.

### @research-fact-checker (Validator)
- **Role**: Validates research outputs against quality, format, and standard-specific rules
- **Model**: Opus | **Color**: Green
- **Tools**: `Glob, Grep, Read, WebFetch, WebSearch`
- **Output**: ACCEPT (certify and deliver) or REJECT with required actions
- **Standard-Aware**: Applies standard-specific validation rules (e.g., verifying IMRaD structure for Academic, answer-first structure for Industry/Professional) in addition to general quality checks

### Mandatory Fact-Check Certification

All research reports must pass fact-check certification before delivery to the user. Reports are validated against layer-appropriate quality criteria (Layers 1-5), so a Layer 2 brief is not held to the same depth requirements as a Layer 3 deep report. However, **all reports regardless of layer** must include: a dedicated Limitations section, a formal Sources and References list with structured entries, and an AI Disclosure note.

1. **Report Generation**: The report generator writes the completed report to `.reports/`
2. **Fact-Check Validation**: The fact-checker reads the report from disk and validates it against the target quality layer
3. **Certification Decision**:
   - **ACCEPT**: Report is certified and delivered to the user
   - **REJECT**: Required actions are specified; generator iterates (max 3 attempts)
4. **Failure Handling**: After 3 failed attempts, the best available report is delivered with caveats

### Agent Interaction Flow

```
User Request
     │
     ▼
Main Claude Instance
     │
     ├── AskUserQuestion: Standard Category (1-9)?
     ├── AskUserQuestion: Report Type?
     │
     ▼
Prepend Report Configuration block
     │
     ▼
@research-assistant (parses config, maps type → layer)
     │
     ├──► @research-report-generator
     │         │ (applies standard formatting + quality layer)
     │         ├──► Spawn subagents (2-8)
     │         │
     │         ▼
     │    Writes report to .reports/
     │         │
     ▼         ▼
@research-fact-checker ◄── Reads report from disk
     │ (applies standard-specific + layer-appropriate validation)
     │
     ├── ACCEPT ──► Certify & Deliver Report
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
- **Orchestrators** (e.g., @research-assistant): `Task, Read, Write, Edit, Grep, Glob` — coordination, file management, searching
- **Generators** (e.g., @research-report-generator): `Task, Glob, Grep, Read, Write, WebFetch, WebSearch` — research, content creation, web access
- **Validators** (e.g., @research-fact-checker): `Glob, Grep, Read, WebFetch, WebSearch` — analysis, verification, fact-checking (no write access)

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
