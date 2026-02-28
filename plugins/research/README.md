# Research Plugin

A coordinated research toolkit for Claude Code and OpenCode CLI featuring three specialized agents that work together to produce high-quality, fact-verified research reports.

## Supported CLIs

This plugin provides agent definitions for both Claude Code and OpenCode:

| CLI | Agent Directory | Format |
|-----|----------------|--------|
| Claude Code | `agents/` | YAML frontmatter with tool arrays, hooks, memory |
| OpenCode | `opencode/agents/` | YAML frontmatter with tool objects, permissions |

## Agents

### @research-assistant
**Orchestrator** (Model: Opus) - Coordinates the research workflow between generation and validation.

- Delegates research tasks to @research-report-generator
- Sends outputs to @research-fact-checker for validation
- Manages the iteration loop (up to 3 attempts) until acceptance
- Delivers final reports with verification status
- **Claude Code**: PreToolUse hook on Write enforces `.reports/` path constraint
- **OpenCode**: System prompt self-enforces `.reports/` write constraint; bash permissions restrict commands

### @research-report-generator
**Generator** (Model: Opus, maxTurns/maxSteps: 50) - Produces comprehensive research reports using parallel subagents.

- Analyzes queries and decomposes into research threads
- Spawns 2-8 specialized subagents for parallel research
- Synthesizes findings into structured reports
- Includes executive summary, methodology, findings, and sources
- **Claude Code**: PreToolUse hook on Write enforces `.temp/` path constraint
- **OpenCode**: System prompt self-enforces `.temp/` write constraint; bash permissions restrict commands

### @research-fact-checker
**Validator** (Model: Sonnet, maxTurns/maxSteps: 30) - Validates research outputs against quality standards.

- Checks output format compliance
- Validates quality standards (sources, accuracy, objectivity)
- Returns ACCEPT or REJECT with required actions
- Provides detailed remediation guidance
- **Claude Code**: `disallowedTools` blocks Write/Edit/Bash/Task; `permissionMode: acceptEdits`; project-scoped `memory`
- **OpenCode**: `write`, `edit`, `bash`, `task` set to `false` in tools config; edit/bash permissions set to `deny`

## Installation

### Claude Code

Install via the marketplace:
```
/plugin install research@agentpalooza
```

### OpenCode CLI

Copy agents to your project:
```bash
mkdir -p .opencode/agents
cp plugins/research/opencode/agents/*.md .opencode/agents/
```

Or install globally:
```bash
mkdir -p ~/.config/opencode/agents
cp plugins/research/opencode/agents/*.md ~/.config/opencode/agents/
```

## Usage

Request comprehensive research with built-in fact-checking:

```
I need a detailed research report on the impact of quantum computing on cryptography
```

### Interactive Selection

Before spawning `@research-assistant`, the host instance will ask you to choose:

1. **Standard Category (1-9)** — determines report structure and formatting style:
   | # | Standard | Key Characteristics |
   |---|----------|-------------------|
   | 1 | Academic | IMRaD structure, formal citations (APA/IEEE) |
   | 2 | Industry/Professional | Pyramid Principle, answer-first, MECE |
   | 3 | Government/Institutional | Objectives-Scope-Findings-Recommendations |
   | 4 | Digital/Web | Metadata-rich, FAIR principles |
   | 5 | Quality Criteria | Balanced multi-criteria assessment |
   | 6 | AI-Report Standards | AI-transparency-first, confidence calibration |
   | 7 | Use-Case Optimized | Auto-matched to report type |
   | 8 | Custom/Hybrid | Configurable blend of standards |
   | 9 | Practical/System-Aligned | Current system patterns |

2. **Report Type** — determines content depth (mapped to quality layers):
   | Report Type | Quality Layer | Typical Length |
   |------------|--------------|----------------|
   | Quick Research Brief | Layer 2 | 1-3 pages |
   | Executive Summary | Layer 2 | 1-2 pages |
   | Deep Technical Report | Layer 3 | 10-30+ pages |
   | Hybrid Report | Layer 3 | Variable |
   | Compliance Report | Layer 4 | Variable |

Your selections are passed as a **Report Configuration** block to all agents in the pipeline, ensuring consistent formatting and validation throughout.

### Workflow

The @research-assistant will:
1. Parse your selected Standard and Report Type
2. Generate initial research via @research-report-generator (with standard-specific formatting)
3. Validate via @research-fact-checker (with standard-specific validation rules)
4. Iterate if needed (max 3 attempts)
5. Deliver the final verified report

## Workflow Diagram

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
@research-assistant
     │
     ├──► @research-report-generator
     │         │ (applies standard formatting + quality layer)
     │         ▼
     │    Draft Report (.temp/)
     │         │
     ▼         ▼
@research-fact-checker
     │ (applies standard-specific + layer-appropriate validation)
     │
     ├── ACCEPT ──► Certify, move .temp/ → .reports/, Deliver
     │
     └── REJECT ──► Loop (max 3x)
```

## CLI-Specific Differences

| Feature | Claude Code | OpenCode |
|---------|------------|----------|
| Path enforcement | PreToolUse hooks (deterministic) | System prompt constraints + bash permissions |
| Tool denial | `disallowedTools` array | `tools` object with `false` values |
| Permission mode | `permissionMode: acceptEdits` | `permission` object with deny rules |
| Persistent memory | `memory: project` on fact-checker | Not supported natively |
| Interactive prompts | `AskUserQuestion` tool | `question` tool |

The core workflow, report format, quality layers, and standard categories are identical across both CLIs. The differences are purely in how each CLI's agent system enforces constraints and manages permissions.
