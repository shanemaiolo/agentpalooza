# Agentpalooza

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

1. Create a new directory under `plugins/`:
   ```
   plugins/
   └── your-plugin/
       ├── .claude-plugin/
       │   └── plugin.json
       ├── agents/
       │   └── your-agent.md
       └── README.md
   ```

2. Create `plugin.json`:
   ```json
   {
     "name": "your-plugin",
     "version": "1.0.0",
     "description": "Your plugin description",
     "agents": ["./agents/"]
   }
   ```

3. Update `.claude-plugin/marketplace.json` to include your plugin:
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

## Structure

```
agentpalooza/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace catalog
├── plugins/
│   └── research/              # Research plugin
│       ├── .claude-plugin/
│       │   └── plugin.json    # Plugin manifest
│       ├── agents/            # Agent definitions
│       └── README.md
├── README.md
└── LICENSE
```

## License

MIT
