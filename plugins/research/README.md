# Research Plugin

A coordinated research toolkit for Claude Code featuring three specialized agents that work together to produce high-quality, fact-verified research reports.

## Agents

### @research-assistant
**Orchestrator** - Coordinates the research workflow between generation and validation.

- Delegates research tasks to @research-report-generator
- Sends outputs to @research-fact-checker for validation
- Manages the iteration loop (up to 3 attempts) until acceptance
- Delivers final reports with verification status

### @research-report-generator
**Generator** - Produces comprehensive research reports using parallel subagents.

- Analyzes queries and decomposes into research threads
- Spawns 2-8 specialized subagents for parallel research
- Synthesizes findings into structured reports
- Includes executive summary, methodology, findings, and sources

### @research-fact-checker
**Validator** - Validates research outputs against quality standards.

- Checks output format compliance
- Validates quality standards (sources, accuracy, objectivity)
- Returns ACCEPT or REJECT with required actions
- Provides detailed remediation guidance

## Usage

Request comprehensive research with built-in fact-checking:

```
I need a detailed research report on the impact of quantum computing on cryptography
```

The @research-assistant will:
1. Generate initial research via @research-report-generator
2. Validate via @research-fact-checker
3. Iterate if needed (max 3 attempts)
4. Deliver the final verified report

## Workflow Diagram

```
User Request
     │
     ▼
@research-assistant
     │
     ├──► @research-report-generator
     │         │
     │         ▼
     │    Research Report
     │         │
     ▼         ▼
@research-fact-checker
     │
     ├── ACCEPT ──► Deliver Report
     │
     └── REJECT ──► Loop (max 3x)
```
