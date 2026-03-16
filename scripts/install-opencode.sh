#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"

usage() {
    cat <<EOF
Usage: $(basename "$0") <project-path> [plugin-name]
       $(basename "$0") --global [plugin-name]

Install agentpalooza OpenCode agents via subdirectory symlinks.

Arguments:
  <project-path>  Path to your project (creates .opencode/agents/ there)
  --global        Install to ~/.config/opencode/agents/ instead
  [plugin-name]   Install a specific plugin (default: all plugins)

Options:
  --force         Replace existing symlinks
  -h, --help      Show this help message
EOF
    exit 0
}

# Parse args
FORCE=false
GLOBAL=false
TARGET_DIR=""
PLUGIN_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        --force) FORCE=true; shift ;;
        --global) GLOBAL=true; shift ;;
        -*)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
        *)
            if [[ -z "$TARGET_DIR" && "$GLOBAL" == false ]]; then
                TARGET_DIR="$1"
            elif [[ -z "$PLUGIN_NAME" ]]; then
                PLUGIN_NAME="$1"
            else
                echo "Error: Unexpected argument $1" >&2
                usage
            fi
            shift
            ;;
    esac
done

if [[ "$GLOBAL" == true ]]; then
    AGENTS_DIR="${HOME}/.config/opencode/agents"
elif [[ -n "$TARGET_DIR" ]]; then
    AGENTS_DIR="$TARGET_DIR/.opencode/agents"
else
    echo "Error: Provide a project path or use --global" >&2
    echo ""
    usage
fi

# Collect plugins to install
plugins=()
if [[ -n "$PLUGIN_NAME" ]]; then
    plugin_agents="$PLUGINS_DIR/$PLUGIN_NAME/opencode/agents"
    if [[ ! -d "$plugin_agents" ]]; then
        echo "Error: Plugin '$PLUGIN_NAME' not found or has no OpenCode agents at:" >&2
        echo "  $plugin_agents" >&2
        exit 1
    fi
    plugins+=("$PLUGIN_NAME")
else
    for dir in "$PLUGINS_DIR"/*/opencode/agents; do
        if [[ -d "$dir" ]]; then
            plugin="$(basename "$(dirname "$(dirname "$dir")")")"
            plugins+=("$plugin")
        fi
    done
    if [[ ${#plugins[@]} -eq 0 ]]; then
        echo "Error: No plugins with OpenCode agents found in $PLUGINS_DIR" >&2
        exit 1
    fi
fi

# Create agents directory
mkdir -p "$AGENTS_DIR"

installed=0
skipped=0

for plugin in "${plugins[@]}"; do
    link_name="agentpalooza-$plugin"
    link_path="$AGENTS_DIR/$link_name"
    source_path="$PLUGINS_DIR/$plugin/opencode/agents"

    if [[ -e "$link_path" || -L "$link_path" ]]; then
        if [[ "$FORCE" == true ]]; then
            rm -f "$link_path"
            echo "Replaced: $link_name"
        else
            echo "Skipped:  $link_name (already exists, use --force to replace)"
            skipped=$((skipped + 1))
            continue
        fi
    fi

    ln -s "$source_path" "$link_path"
    installed=$((installed + 1))

    # List agents in this plugin
    agents=()
    for agent_file in "$source_path"/*.md; do
        if [[ -f "$agent_file" ]]; then
            agents+=("$(basename "$agent_file" .md)")
        fi
    done
    echo "Installed: $link_name -> $source_path"
    if [[ ${#agents[@]} -gt 0 ]]; then
        for agent in "${agents[@]}"; do
            echo "          @$agent"
        done
    fi
done

echo ""
echo "Done: $installed installed, $skipped skipped"
echo "Agents directory: $AGENTS_DIR"
