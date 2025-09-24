# JIDO Conductor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Elixir](https://img.shields.io/badge/Elixir-1.16%2B-purple)](https://elixir-lang.org/)
[![Rust](https://img.shields.io/badge/Rust-1.70%2B-orange)](https://www.rust-lang.org/)
[![React](https://img.shields.io/badge/React-18-blue)](https://reactjs.org/)
[![Tauri](https://img.shields.io/badge/Tauri-2.0-FFC131)](https://tauri.app/)
[![JIDO Framework](https://img.shields.io/badge/JIDO-1.0.0-green)](https://github.com/agentjido/jido)

A desktop application for managing, running, and monitoring JIDO agents with a Conductor-style UI.

## Architecture

- **Desktop Shell**: Tauri (Rust) + React 18 + TypeScript + Vite + Tailwind CSS + shadcn/ui
- **Agent Runtime**: Elixir (JIDO) + Phoenix/Bandit (local HTTP server on port 8745)
- **Storage**: SQLite (dev) / PostgreSQL (prod)
- **Security**: Loopback-only HTTP, OS Keychain for secrets, strict Tauri allowlist

## Project Structure

```
app/                     # Tauri + React desktop application
agent_service/           # Elixir + JIDO agent service
templates/               # Agent templates
.claude/                 # Claude Code integration
```

## Features

- Template gallery with import/export (.jido.zip)
- Schema-driven configuration with validation
- Live monitoring with SSE log streaming
- Budget management and cost tracking
- Secure secrets management via OS Keychain
- Claude Code CLI integration
- Agent-OS 3-layer context support
- Offline-first with optional online features

## Development

### Prerequisites
- Rust & Cargo
- Node.js 20+ & Bun/PNPM
- Elixir 1.16+ & Erlang/OTP 26+
- Claude Code CLI (for agent execution)

### Setup
```bash
# Install dependencies
cd app && bun install
cd ../agent_service && mix deps.get

# Run development servers
cd app && bun run tauri dev
cd agent_service && mix phx.server
```

## Security Model

- Loopback-only HTTP (127.0.0.1:8745)
- Per-session random bearer tokens
- Secrets stored in OS Keychain, never on disk
- Strict Tauri shell allowlist
- No background networking unless explicitly enabled
- Template sandboxing with network allowlists