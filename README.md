# jido-conductor

Desktop application for managing JIDO autonomous agents. Tauri shell (Rust) with a React frontend and an Elixir agent service backend.

## Status

Early development. The Tauri + React shell renders and the Elixir agent service starts, but the two halves communicate over a loopback HTTP API that is partially wired. No packaged releases exist.

| Component | State |
|---|---|
| Desktop shell (Tauri 2 + React 18) | UI scaffolded with shadcn/ui; template gallery, run management pages |
| Agent service (Elixir + JIDO) | Phoenix API on port 8745; template registry, run worker, SSE log streaming |
| Conductor.json support | Parser and executor implemented |
| Tests | 1 test config file (`test.exs`); no test modules |
| CI | 3 workflow files (CI, build-release, semantic-release) |
| Releases | None published |

## What it does

1. Users browse and import agent templates (`.jido.zip` archives with a `conductor.json` manifest)
2. Configure runs with schema-validated parameters
3. The agent service executes runs in isolated workspaces via setup/run/archive shell scripts
4. Live logs stream back to the desktop UI over SSE
5. Budget tracking and cost management per run

### conductor.json format

```json
{
  "name": "my-template",
  "version": "1.0.0",
  "setup": "scripts/setup.sh",
  "run": "scripts/run.sh",
  "archive": "scripts/archive.sh",
  "env": { "API_KEY": "value" },
  "timeout": 3600,
  "budget": { "max_usd": 10.0 }
}
```

## Stack

| Layer | Technology | Version |
|---|---|---|
| Desktop shell | Tauri (Rust) | 2.0 |
| Frontend | React 18, TypeScript, Vite, Tailwind, shadcn/ui | See `app/package.json` |
| State management | Zustand | 5.x |
| Agent runtime | Elixir, JIDO framework | 1.16+ / jido ~> 1.2.0 |
| Web framework | Phoenix + Bandit | ~> 1.7.14 |
| Database | SQLite (dev), PostgreSQL (prod) | ecto_sqlite3 ~> 0.17 |
| Forms | react-hook-form + zod | -- |

## Repository layout

```
app/                    Tauri + React desktop app
  src-tauri/            Rust shell, capabilities, icons
  src/                  React components, pages, stores
agent_service/          Elixir Phoenix service
  lib/agent_service/    Actions, agents, config, providers, runs, sensors, templates
  priv/templates/       Example conductor.json template
.github/workflows/      CI, build-release, semantic-release
```

161 files total.

## Setup

Requires Rust, Node.js 20+ (Bun or pnpm), Elixir 1.16+, Erlang/OTP 26+.

```bash
# Frontend
cd app && bun install

# Backend
cd agent_service && mix deps.get

# Development
cd app && bun run tauri dev       # starts both Tauri shell and Vite dev server
cd agent_service && mix phx.server # agent service on port 8745
```

## Security model

- HTTP server binds to 127.0.0.1 only
- Per-session random bearer tokens
- Secrets in OS keychain, not on disk
- Tauri shell allowlist restricts subprocess execution

## Limitations

- No test suite. The single `test.exs` is a config file, not a test module.
- No packaged binaries or installers. Must build from source.
- The JIDO framework dependency (`jido ~> 1.2.0`) is not on hex.pm; requires access to the agentjido GitHub org.
- `jido_ai` dependency is pinned to a GitHub repo with no version constraint.
- Claude Code CLI is assumed available for agent execution but is not bundled or documented for installation.
- Conventional commits are enforced (commitlint + husky) but semantic-release has not produced any releases.

## License

MIT