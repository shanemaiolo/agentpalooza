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

### Interactive Selection

Before spawning `@research-assistant`, the main Claude instance will ask you to choose:

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
Main Claude Instance
     │
     ├── AskUserQuestion: Standard Category (1-9)?
     ├── AskUserQuestion: Report Type?
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
