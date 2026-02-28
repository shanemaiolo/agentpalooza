# AGENTS.md - Agentpalooza Project Guide

## Project Overview

Agentpalooza is a plugin marketplace for Claude Code and OpenCode CLI that distributes reusable agents and skills across projects. Users can add the marketplace to their environment and install individual plugins containing coordinated multi-agent workflows.

## Supported CLIs

| CLI | Agent Format | Distribution |
|-----|-------------|-------------|
| Claude Code | `.claude-plugin/` manifests, YAML frontmatter agents | Plugin marketplace (`/plugin install`) |
| OpenCode | `.opencode/agents/` markdown files, YAML frontmatter | Copy agent files to project or global config |

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
│       ├── agents/            # Claude Code agent definitions
│       │   ├── research-assistant.md
│       │   ├── research-fact-checker.md
│       │   └── research-report-generator.md
│       ├── opencode/
│       │   └── agents/        # OpenCode agent definitions
│       │       ├── research-assistant.md
│       │       ├── research-fact-checker.md
│       │       └── research-report-generator.md
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
  ],
  "opencode": {
    "agents": [
      "./opencode/agents/agent-name.md"
    ]
  }
}
```

**Critical**: The `agents` field must be an **array of individual file paths**, not a directory path. Paths are resolved relative to the plugin root (the directory containing `.claude-plugin/`).

### Marketplace Registry (`marketplace.json`)

The root marketplace catalog lists all available plugins:

```json
{
  "name": "agentpalooza",
  "version": "1.4.0",
  "metadata": {
    "pluginRoot": "./plugins",
    "supportedCLIs": ["claude-code", "opencode"]
  },
  "plugins": [
    {
      "name": "research",
      "source": "./plugins/research",
      "tags": ["research", "fact-checking", "agents"],
      "supportedCLIs": ["claude-code", "opencode"]
    }
  ]
}
```

## Agent Definition Formats

Each plugin contains two sets of agent definitions — one for Claude Code and one for OpenCode — in separate directories. The system prompts are functionally identical; only the YAML frontmatter differs to match each CLI's configuration schema.

### Claude Code Agent Format

Located in `plugins/{plugin}/agents/`:

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
- `model`: Claude model (e.g., "opus", "sonnet", "haiku", "inherit")
- `color`: UI color identifier

**Optional Fields**:
- `disallowedTools`: Tools to explicitly deny (defense-in-depth alongside `tools`)
- `maxTurns`: Maximum agentic turns before stopping (prevents runaway agents)
- `permissionMode`: Permission behavior (`default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`)
- `memory`: Persistent memory scope (`user`, `project`, `local`) for cross-session learning
- `hooks`: Lifecycle hooks scoped to this agent (PreToolUse, PostToolUse, Stop)

### OpenCode Agent Format

Located in `plugins/{plugin}/opencode/agents/`:

```yaml
---
name: agent-name
description: "Description with usage examples"
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
permission:
  edit: deny
  bash:
    - "* deny"
    - "specific-command allow"
---

[System prompt and operational guidelines in markdown]
```

**Required Fields**:
- `name`: Agent identifier (kebab-case, same as Claude Code counterpart)
- `description`: Usage description with examples

**Optional Fields**:
- `mode`: Agent type — `primary` (can be default agent), `subagent` (invoked via task tool), or `all` (both)
- `model`: Full provider/model string (e.g., `anthropic/claude-opus-4`, `anthropic/claude-sonnet-4`)
- `maxSteps`: Maximum agentic iterations before forced text-only response
- `tools`: Object map of tool names to `true`/`false` for enabling/disabling
- `temperature`: LLM temperature (0 = deterministic, higher = creative)
- `hidden`: Hide from `@` autocomplete (useful for internal subagents)
- `permission`: Per-tool permission rules (`ask`, `allow`, `deny`, or glob arrays for bash)

### Cross-CLI Field Mapping

| Feature | Claude Code | OpenCode |
|---------|------------|----------|
| Tool list | `tools: [Task, Read, Write]` | `tools:` object with `task: true, read: true, write: true` |
| Tool denial | `disallowedTools: [Write, Edit]` | `write: false, edit: false` in `tools:` |
| Model | `model: opus` | `model: anthropic/claude-opus-4` |
| Turn/step limit | `maxTurns: 50` | `maxSteps: 50` |
| Agent mode | Implicit | `mode: primary\|subagent\|all` |
| Hooks | `hooks:` block (PreToolUse, PostToolUse, Stop) | Not supported per-agent; use system prompt constraints |
| UI color | `color: cyan` | Not supported |
| Memory | `memory: project` | Not supported natively |
| Permissions | `permissionMode: acceptEdits` | `permission:` object per tool |
| Interactive prompts | `AskUserQuestion` tool | `question` tool |

### Available Tools by CLI

**Claude Code tools**: `Task`, `Read`, `Write`, `Edit`, `Bash`, `Grep`, `Glob`, `WebFetch`, `WebSearch`

**OpenCode tools**: `task`, `read`, `write`, `edit`, `bash`, `grep`, `glob`, `list`, `webfetch`, `websearch`, `question`, `skill`, `todo`, `patch`, `lsp`

### Model Name Mapping

| Claude Code | OpenCode |
|------------|----------|
| `opus` | `anthropic/claude-opus-4` |
| `sonnet` | `anthropic/claude-sonnet-4` |
| `haiku` | `anthropic/claude-haiku-4-5` |

OpenCode supports 75+ providers beyond Anthropic (OpenAI, Google, Ollama, AWS Bedrock, etc.). Use `opencode models` to see all available models.

## Research Plugin Agents

### Claude Code Agents (`plugins/research/agents/`)

### @research-assistant (Orchestrator)
- **Role**: Coordinates research workflow between generation and validation
- **Model**: Opus | **Color**: Pink
- **Tools**: `Task, Read, Write, Edit, Bash, Grep, Glob`
- **Hooks**: PreToolUse on Write — enforces `.reports/` path constraint
- **Workflow**: Parses the Report Configuration block (Standard Category + Report Type), maps Report Type to Quality Layer, then manages iterative verification cycles (max 3 attempts)
- **Pre-spawn Requirement**: The main Claude instance must ask the user for Standard Category (1-9) and Report Type via `AskUserQuestion` before launching this agent, prepending selections as a `**Report Configuration**` block

### @research-report-generator (Generator)
- **Role**: Produces comprehensive research reports using parallel subagents
- **Model**: Opus | **Color**: Cyan | **maxTurns**: 50
- **Tools**: `Task, Glob, Grep, Read, Write, WebFetch, WebSearch`
- **Hooks**: PreToolUse on Write — enforces `.temp/` path constraint
- **Spawns**: 2-8 specialized subagents for parallel research (Haiku for web search, Sonnet for analysis, maxTurns: 15)
- **Output**: Writes drafts to `.temp/{topic-slug}-{timestamp}.md` (moved to `.reports/` by @research-assistant after certification)
- **Quality Layers**: Supports 5 report quality layers (Layer 1 Base through Layer 5 Publication-Ready). All reports at every layer must include: Limitations section, Sources and References, and AI Disclosure.
- **Standard Categories**: Supports 9 report standards (Academic, Industry/Professional, Government/Institutional, Digital/Web, Quality Criteria, AI-Report Standards, Use-Case Optimized, Custom/Hybrid, Practical/System-Aligned) that govern formatting and structure independently from quality layers.

### @research-fact-checker (Validator)
- **Role**: Validates research outputs against quality, format, and standard-specific rules
- **Model**: Sonnet | **Color**: Green | **maxTurns**: 30
- **Tools**: `Glob, Grep, Read, WebFetch, WebSearch` | **disallowedTools**: `Write, Edit, Bash, Task`
- **permissionMode**: `acceptEdits` — auto-approves read operations for uninterrupted validation
- **Memory**: Project-scoped persistent memory for tracking validation patterns across sessions
- **Output**: ACCEPT (certify and deliver) or REJECT with required actions
- **Standard-Aware**: Applies standard-specific validation rules (e.g., verifying IMRaD structure for Academic, answer-first structure for Industry/Professional) in addition to general quality checks

### OpenCode Agents (`plugins/research/opencode/agents/`)

### @research-assistant (Orchestrator)
- **Role**: Same as Claude Code version — coordinates research workflow
- **Model**: `anthropic/claude-opus-4` | **Mode**: `primary`
- **Tools**: `task, read, write, edit, bash, grep, glob, list`
- **Path Enforcement**: System prompt self-enforces `.reports/` write constraint (OpenCode lacks per-agent hooks)
- **Bash Permissions**: Restricted to `mkdir -p .reports` and `rm .temp/*`
- **Pre-spawn Requirement**: Same interactive selection flow using OpenCode's `question` tool

### @research-report-generator (Generator)
- **Role**: Same as Claude Code version — produces research reports with parallel subagents
- **Model**: `anthropic/claude-opus-4` | **Mode**: `subagent` | **maxSteps**: 50
- **Tools**: `task, read, write, bash, grep, glob, list, webfetch, websearch`
- **Path Enforcement**: System prompt self-enforces `.temp/` write constraint
- **Bash Permissions**: Restricted to `mkdir -p .temp`

### @research-fact-checker (Validator)
- **Role**: Same as Claude Code version — validates research outputs
- **Model**: `anthropic/claude-sonnet-4` | **Mode**: `subagent` | **maxSteps**: 30
- **Tools**: `read, grep, glob, list, webfetch, websearch` (task/write/edit/bash all disabled)
- **Permissions**: `edit: deny`, `bash: deny` — enforces read-only behavior

### Mandatory Fact-Check Certification

All research reports must pass fact-check certification before delivery to the user. Reports are validated against layer-appropriate quality criteria (Layers 1-5), so a Layer 2 brief is not held to the same depth requirements as a Layer 3 deep report. However, **all reports regardless of layer** must include: a dedicated Limitations section, a formal Sources and References list with structured entries, and an AI Disclosure note.

1. **Report Generation**: The report generator writes the draft to `.temp/`
2. **Fact-Check Validation**: The fact-checker reads the draft from disk and validates it against the target quality layer
3. **Certification Decision**:
   - **ACCEPT**: Report is certified, moved from `.temp/` to `.reports/`, and delivered to the user
   - **REJECT**: Required actions are specified; generator iterates on the `.temp/` draft (max 3 attempts)
4. **Finalization**: After acceptance (or max iterations), the assistant writes the certified report to `.reports/` and deletes the `.temp/` file
5. **Failure Handling**: After 3 failed attempts, the best available report is moved to `.reports/` and delivered with caveats

### Agent Interaction Flow

```
User Request
     │
     ▼
Host Instance (Claude Code or OpenCode)
     │
     ├── Interactive Selection: Standard Category (1-9)?
     ├── Interactive Selection: Report Type?
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
     │    Writes draft to .temp/
     │         │
     ▼         ▼
@research-fact-checker ◄── Reads draft from disk
     │ (applies standard-specific + layer-appropriate validation)
     │
     ├── ACCEPT ──► Certify, move .temp/ → .reports/, Deliver
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
- Agent names are shared across CLIs — the same `@research-assistant` identifier works in both Claude Code and OpenCode

### Tool Assignment Strategy

Different agents should receive tools appropriate to their responsibilities:

**Claude Code:**
- **Orchestrators** (e.g., @research-assistant): `Task, Read, Write, Edit, Bash, Grep, Glob` — coordination, file management, searching, temp file cleanup
- **Generators** (e.g., @research-report-generator): `Task, Glob, Grep, Read, Write, WebFetch, WebSearch` — research, content creation, web access
- **Validators** (e.g., @research-fact-checker): `Glob, Grep, Read, WebFetch, WebSearch` — analysis, verification, fact-checking (no write access). Use `disallowedTools` to explicitly deny `Write, Edit, Bash, Task` for defense-in-depth.

**OpenCode:**
- **Orchestrators**: `task, read, write, edit, bash, grep, glob, list` with bash permission restrictions
- **Generators**: `task, read, write, bash, grep, glob, list, webfetch, websearch` with bash permission restrictions
- **Validators**: `read, grep, glob, list, webfetch, websearch` with `task: false, write: false, edit: false, bash: false` and `permission.edit: deny, permission.bash: deny`

### Model Selection Strategy

Match model to task complexity for cost optimization:
- **Orchestrators**: Opus — complex reasoning for workflow coordination
- **Generators**: Opus — high-quality synthesis and report writing
- **Validators**: Sonnet — structured checklist validation is well-scoped
- **Research subagents**: Haiku for web search/information gathering, Sonnet for analysis-heavy threads

### Safety and Reliability Features

**Shared across CLIs:**
- **Turn/step limits**: Set limits to prevent runaway agents (e.g., 50 for generators, 30 for validators, 15 for research subagents)
- **Tool restriction**: Only grant tools each agent role needs

**Claude Code specific:**
- **Hooks**: Use PreToolUse hooks to enforce file path constraints deterministically (e.g., generator writes only to `.temp/`, orchestrator writes only to `.reports/`)
- **permissionMode**: Use `acceptEdits` for read-only agents to streamline operations
- **memory**: Use project-scoped persistent memory for agents that benefit from cross-session learning (e.g., fact-checker tracking recurring validation patterns)

**OpenCode specific:**
- **System prompt constraints**: Since OpenCode lacks per-agent hooks, embed path enforcement rules in the agent's system prompt (e.g., "ONLY write files to `.temp/`")
- **Bash permissions**: Use glob-based bash permission rules to restrict shell commands (e.g., deny all, then allow specific commands)
- **Tool disabling**: Set tools to `false` in the tools object for hard denial (more reliable than system prompt rules alone)
- **Permission deny rules**: Use `permission.edit: deny` and `permission.bash: deny` for defense-in-depth on read-only agents

### Adapting Agents Across CLIs

When creating OpenCode versions of Claude Code agents:

1. **Convert tool arrays to objects**: `tools: [Read, Write]` → `tools: { read: true, write: true }`
2. **Map model names**: `opus` → `anthropic/claude-opus-4`
3. **Replace maxTurns with maxSteps**: Same concept, different field name
4. **Replace hooks with system prompt rules**: Embed path constraints as "CRITICAL CONSTRAINT" sections in the system prompt
5. **Replace disallowedTools with tool disabling**: Set unwanted tools to `false` in the tools object
6. **Replace permissionMode with permission rules**: Map `acceptEdits` to explicit `permission.edit: deny` etc.
7. **Set mode**: Choose `primary` for top-level agents, `subagent` for agents invoked via task tool
8. **Drop unsupported fields**: `color` and `memory` have no OpenCode equivalents

## Development Guidelines

1. **Dual CLI Support**: When adding agents, create both Claude Code (`agents/`) and OpenCode (`opencode/agents/`) versions
2. **Plugin Structure**: Always include `.claude-plugin/plugin.json` in the plugin directory
3. **Agent Files**: Place Claude Code agents in `agents/` and OpenCode agents in `opencode/agents/`
4. **Explicit Paths**: List each agent file individually in the manifest
5. **Shared Names**: Use identical agent names across CLIs for consistency
6. **System Prompts**: Keep system prompt content functionally identical across CLIs; only adapt for CLI-specific tool naming or constraint mechanisms
7. **Documentation**: Include README.md explaining workflow, usage, and CLI-specific differences
8. **Examples**: Agent descriptions should include usage examples with commentary

## Permissions

### Claude Code

Local settings (`.claude/settings.local.json`) control tool access:
```json
{
  "permissions": {
    "allow": ["Bash(git add:*)", "Bash(git commit:*)"]
  }
}
```

### OpenCode

Permissions are set per-agent in the YAML frontmatter:
```yaml
permission:
  edit: deny
  bash:
    - "* deny"
    - "mkdir -p .reports allow"
    - "rm .temp/* allow"
```

Or globally in `opencode.json`:
```json
{
  "permission": {
    "bash": "ask",
    "edit": "ask"
  }
}
```
