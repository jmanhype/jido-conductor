# Conductor vs JIDO Conductor Comparison

## Overview

This document compares the original Conductor application with JIDO Conductor to understand alignment and differences.

## Conductor (Original)

### Core Concept
- **Purpose**: Mac app to run multiple Claude AI agents simultaneously
- **Philosophy**: Each agent gets an isolated copy of the codebase
- **Focus**: Managing multiple AI coding assistants with easy review/merge

### Key Features
1. **Parallel Agents**: Run multiple Claude instances concurrently
2. **Dispatcher**: Create workspaces with custom names or from Linear issues
3. **Diff Viewer**: Visualize changes made by Claude agents
4. **MCP Integration**: Connect to external tools and data sources
5. **Slash Commands**: Execute custom commands within chat

### Configuration
- Uses `conductor.json` for scripting and automation
- Three script types:
  - `setup`: Runs when workspace is created
  - `run`: Launches servers/apps/tests
  - `archive`: Cleanup when workspace is archived
- Example:
  ```json
  {
    "scripts": {
      "setup": "npm install; cp $CONDUCTOR_ROOT_PATH/.env .env",
      "run": "npm run dev",
      "archive": "rm -rf cleanup_files"
    }
  }
  ```

### Environment Variables
- `CONDUCTOR_WORKSPACE_NAME`: Workspace name
- `CONDUCTOR_WORKSPACE_PATH`: Workspace path
- `CONDUCTOR_ROOT_PATH`: Repository root
- `CONDUCTOR_DEFAULT_BRANCH`: Default branch (defaults to "main")
- `CONDUCTOR_PORT`: First port in range of 10 assigned ports

### Authentication
- No login required for local operation
- API keys stored in OS keychain
- Local-only service model

## JIDO Conductor

### Core Concept
- **Purpose**: Desktop app for managing JIDO agents with Claude integration
- **Philosophy**: Template-based agent creation and management
- **Focus**: Running and monitoring JIDO agents with real-time logs

### Key Features
1. **Template Management**: Create/edit/manage agent templates
2. **Run Management**: Execute and monitor agent runs
3. **Real-time Logs**: SSE-based log streaming
4. **Claude Integration**: Direct integration with Claude CLI
5. **State Management**: Track run states and history

### Configuration
- Currently uses:
  - Environment variables for API configuration
  - OS keychain for API key storage
  - Local SQLite for state persistence
- **Missing**: No equivalent to `conductor.json`

### Environment Variables (Current)
- `PORT`: Server port (default 8745)
- `ANTHROPIC_API_KEY`: Stored in OS keychain
- No workspace-specific environment variables

### Authentication
- ✅ No login required (matches Conductor)
- ✅ Local session tokens (UUID-based)
- ✅ OS keychain for API keys (matches Conductor)

## Alignment Analysis

### ✅ Already Aligned
1. **No-login model**: Both use local-only authentication
2. **OS Keychain**: Both store API keys securely
3. **Local service**: Both run as local services
4. **Real-time updates**: Both provide live feedback

### ❌ Missing from JIDO Conductor
1. **Workspace isolation**: No isolated workspace copies
2. **conductor.json**: No equivalent configuration file
3. **Script lifecycle**: No setup/run/archive scripts
4. **Environment variables**: No workspace-specific env vars
5. **Multiple parallel agents**: Focus on single agent runs
6. **Diff viewer**: No built-in change visualization

### 🔄 Different Approach
1. **Templates vs Workspaces**: JIDO uses templates, Conductor uses workspaces
2. **Agent framework**: JIDO uses Elixir agents, Conductor uses Claude directly
3. **Configuration**: JIDO uses API/UI, Conductor uses conductor.json

## Recommendations for Alignment

### High Priority
1. **Add conductor.json support**:
   ```json
   {
     "scripts": {
       "setup": "./scripts/setup.sh",
       "run": "cd agent_service && mix phx.server",
       "archive": "./scripts/cleanup.sh"
     },
     "templates": {
       "default": "base_template.yaml"
     }
   }
   ```

2. **Add workspace environment variables**:
   - `JIDO_WORKSPACE_NAME`
   - `JIDO_WORKSPACE_PATH`
   - `JIDO_ROOT_PATH`
   - `JIDO_TEMPLATE_NAME`
   - `JIDO_RUN_ID`

3. **Implement workspace isolation**:
   - Copy codebase for each run
   - Isolate agent execution environments
   - Track changes per workspace

### Medium Priority
1. **Add diff viewer**: Show changes made by agents
2. **Support parallel runs**: Allow multiple agents simultaneously
3. **Linear integration**: Import tasks from Linear

### Low Priority
1. **Slash commands**: Add custom command support
2. **MCP tools**: Extend tool integration
3. **Archive scripts**: Cleanup on run completion

## Implementation Plan

### Phase 1: Core Alignment
- [ ] Implement conductor.json parser
- [ ] Add workspace environment variables
- [ ] Create workspace isolation system

### Phase 2: Feature Parity
- [ ] Add diff viewer component
- [ ] Support parallel agent runs
- [ ] Implement script lifecycle

### Phase 3: Enhanced Features
- [ ] Linear integration
- [ ] Extended MCP support
- [ ] Custom slash commands

## Conclusion

JIDO Conductor shares the core philosophy of Conductor (no-login, local service, AI agent management) but takes a different approach with template-based agent management rather than workspace-based Claude management. To achieve better alignment, the priority should be adding conductor.json support and workspace isolation features while maintaining the strengths of the JIDO agent framework.