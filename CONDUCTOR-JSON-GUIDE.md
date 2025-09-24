# Conductor.json Configuration Guide

JIDO Conductor now supports `conductor.json` configuration files, providing compatibility with Conductor's template format and enabling powerful workspace isolation and script lifecycle management.

## Overview

The `conductor.json` file defines how a template should be executed, including:
- Environment variables
- Setup, run, and archive scripts
- Resource limits and budgets
- Execution timeouts
- Parallel execution settings

## Configuration Structure

```json
{
  "name": "template-name",
  "version": "1.0.0",
  "description": "Template description",
  "setup": "scripts/setup.sh",
  "run": "scripts/run.sh",
  "archive": "scripts/archive.sh",
  "env": {
    "KEY": "value"
  },
  "requirements": {
    "runtime": "bash",
    "min_version": "4.0",
    "dependencies": ["curl", "jq"]
  },
  "parallel": false,
  "timeout": 3600,
  "budget": {
    "max_usd": 10.0,
    "max_tokens": 100000
  }
}
```

## Fields

### Core Fields

- `name` (string): Template identifier
- `version` (string): Template version using semantic versioning
- `description` (string): Human-readable description

### Script Lifecycle

- `setup` (string, optional): Path to setup script, runs before main execution
- `run` (string, optional): Path to main execution script
- `archive` (string, optional): Path to archive script, runs after execution

Scripts can be written in:
- Bash (`.sh`)
- Python (`.py`)
- Node.js (`.js`)
- TypeScript (`.ts`)
- Elixir (`.exs`)

### Environment Variables

- `env` (object): Key-value pairs of environment variables
  - Variables are available to all scripts
  - Merged with system environment
  - Template-specific variables override system ones

### Special Environment Variables

The following variables are automatically provided to scripts:

- `WORKSPACE_DIR`: Isolated workspace directory for this run
- `TEMPLATE_NAME`: Name from conductor.json
- `TEMPLATE_VERSION`: Version from conductor.json  
- `SCRIPT_TYPE`: Current script phase (setup/run/archive)

### Resource Limits

- `timeout` (integer): Maximum execution time in seconds (default: 3600)
- `budget` (object): Cost and token limits
  - `max_usd` (number): Maximum cost in USD
  - `max_tokens` (integer): Maximum token usage

### Execution Settings

- `parallel` (boolean): Enable parallel agent execution (default: false)
- `requirements` (object): Runtime requirements and dependencies

## Workspace Isolation

Each template run gets an isolated workspace:

```
/tmp/jido_workspaces/
  └── template-name/
      └── run-id/
          ├── conductor.json
          ├── scripts/
          ├── output/
          ├── logs/
          └── archive/
```

## Example Template

See `/agent_service/priv/templates/example/` for a complete example template with conductor.json configuration.

### Basic Example

```json
{
  "name": "web-scraper",
  "version": "1.0.0",
  "description": "Scrapes and analyzes web content",
  "run": "scrape.py",
  "env": {
    "SCRAPE_TIMEOUT": "30",
    "OUTPUT_FORMAT": "json"
  },
  "timeout": 600,
  "budget": {
    "max_tokens": 10000
  }
}
```

### Advanced Example with All Phases

```json
{
  "name": "data-processor",
  "version": "2.0.0",
  "description": "Complex data processing pipeline",
  "setup": "scripts/install_deps.sh",
  "run": "scripts/process.py",
  "archive": "scripts/upload_results.sh",
  "env": {
    "PYTHON_VERSION": "3.11",
    "PROCESSING_MODE": "batch",
    "BATCH_SIZE": "1000"
  },
  "parallel": true,
  "timeout": 7200,
  "budget": {
    "max_usd": 25.0,
    "max_tokens": 500000
  }
}
```

## Migration from JIDO Templates

Existing JIDO templates can be enhanced with conductor.json:

1. Keep existing `jido-template.yaml` for JIDO-specific features
2. Add `conductor.json` for script lifecycle and environment management
3. Both configurations will be loaded and merged

## Best Practices

1. **Use relative paths**: Scripts should be relative to template root
2. **Check environment**: Scripts should validate required env vars
3. **Handle errors gracefully**: Use proper exit codes
4. **Clean up in archive**: Remove temporary files, upload results
5. **Set reasonable timeouts**: Prevent runaway executions
6. **Configure budgets**: Protect against unexpected costs

## Compatibility with Conductor

This implementation aims for compatibility with Conductor's configuration format. Templates written for Conductor should work with minimal modifications in JIDO Conductor.

Key differences:
- JIDO Conductor integrates with JIDO's agent framework
- Additional LLM-specific budget controls
- Enhanced security through OS keychain integration

## API Usage

The conductor.json configuration is automatically loaded when starting a template run:

```elixir
# In Elixir backend
{:ok, config} = ConductorConfig.load_from_template(template_path)
env = ConductorConfig.get_env(config)
timeout = ConductorConfig.get_timeout(config)
```

## Troubleshooting

### Scripts Not Executing
- Ensure scripts have executable permissions (`chmod +x`)
- Check script paths are relative to template root
- Verify script interpreter is available

### Environment Variables Not Available
- Check JSON syntax in conductor.json
- Ensure variables are strings
- Use `env` command in scripts to debug

### Workspace Issues
- Verify write permissions to `/tmp/jido_workspaces`
- Check disk space availability
- Ensure unique run IDs to prevent conflicts

## Future Enhancements

Planned features for conductor.json support:
- Cloud workspace backends (S3, GCS)
- Distributed parallel execution
- Template composition and inheritance
- Secret management integration
- Resource monitoring and alerts