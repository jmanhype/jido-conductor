# Agent Service Test Suite

## Overview

This test suite provides comprehensive coverage for the core JIDO Conductor agent service modules.

## Running Tests

```bash
cd agent_service
mix test
```

Run with coverage:
```bash
mix test --cover
```

Run specific test file:
```bash
mix test test/agent_service/config/conductor_config_test.exs
```

## Test Structure

```
test/
├── test_helper.exs                              # Test configuration
├── agent_service/
│   ├── config/
│   │   └── conductor_config_test.exs           # ConductorConfig module tests
│   ├── templates/
│   │   └── template_test.exs                   # Template struct tests
│   └── runs_test.exs                           # Runs context tests
```

## Test Coverage

### ConductorConfig Tests
- Configuration validation (scripts, env, budget)
- Environment variable merging and precedence
- Script path resolution
- Timeout and parallel execution settings
- Budget constraint parsing

### Template Tests
- Template creation from manifest
- Default value handling
- Metadata parsing

### Runs Tests
- Basic parameter structure validation
- Run parameter requirements

## Future Test Additions

The following areas would benefit from additional test coverage:

1. **ScriptExecutor** - Integration tests for script execution lifecycle
2. **Templates.Registry** - GenServer state management and template installation
3. **Runs.Worker** - Worker process lifecycle and error handling
4. **Controllers** - HTTP endpoint integration tests
5. **End-to-End** - Full workflow tests from template upload to run completion

## Notes

- Tests use `async: true` where possible for parallel execution
- Integration tests requiring full application context use `async: false`
- Mock data and fixtures should be added to `test/support/` as needed
