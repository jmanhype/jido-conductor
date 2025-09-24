# JIDO Conductor Architecture

## Overview

JIDO Conductor is a desktop application that provides a graphical interface for managing and running JIDO agents. It follows a hybrid architecture combining a native desktop shell with a local web service.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      User Interface                         │
│                   (Tauri + React + TypeScript)              │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ IPC & HTTP
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                         Tauri Core                          │
│                     (Rust Application)                      │
├─────────────────────────────────────────────────────────────┤
│  • Window Management    • File System Access                │
│  • OS Integration       • Security & Permissions            │
│  • Shell Commands       • Keychain Access                   │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ HTTP (127.0.0.1:8745)
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                     Agent Service                           │
│               (Elixir + Phoenix + JIDO)                     │
├─────────────────────────────────────────────────────────────┤
│  • JIDO Agent Runtime   • Template Management               │
│  • Workflow Execution   • API Endpoints                     │
│  • State Management     • Event Broadcasting                │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                    External Services                        │
├─────────────────────────────────────────────────────────────┤
│  • Claude Code CLI     • External APIs                      │
│  • OS Keychain         • File System                        │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### Frontend (React/TypeScript)

```
app/src/
├── components/          # Reusable UI components
│   ├── ui/             # Base UI components (shadcn/ui)
│   ├── templates/      # Template-related components
│   ├── runs/           # Run management components
│   └── common/         # Shared components
├── pages/              # Route-based pages
│   ├── Dashboard.tsx   # Main dashboard
│   ├── Templates.tsx   # Template gallery
│   ├── Runs.tsx        # Active runs view
│   └── Settings.tsx    # Application settings
├── services/           # Business logic & API
│   ├── api.ts          # API client
│   ├── auth.ts         # Authentication
│   └── websocket.ts    # Real-time communications
├── store/              # State management (Zustand)
│   ├── auth.ts         # Auth state
│   ├── templates.ts    # Template state
│   └── runs.ts         # Run state
└── types/              # TypeScript definitions
```

### Backend (Elixir/JIDO)

```
agent_service/lib/
├── agent_service/
│   ├── actions/        # JIDO Actions
│   │   ├── claude_chat.ex
│   │   ├── fetch_url.ex
│   │   └── save_artifact.ex
│   ├── agents/         # JIDO Agents
│   │   └── template_runner.ex
│   ├── workflows/      # JIDO Workflows
│   │   ├── base_workflow.ex
│   │   └── web_monitor_workflow.ex
│   ├── runs/           # Run management
│   │   ├── supervisor.ex
│   │   ├── jido_worker.ex
│   │   └── store.ex
│   └── templates/      # Template system
│       ├── registry.ex
│       └── template.ex
└── agent_service_web/
    ├── controllers/    # API controllers
    ├── channels/       # WebSocket channels
    └── router.ex       # Route definitions
```

## Data Flow

### Agent Execution Flow

```
1. User creates run configuration
   ↓
2. Frontend sends POST /api/runs
   ↓
3. Agent Service validates request
   ↓
4. JidoWorker spawns JIDO Agent
   ↓
5. Agent executes actions/workflows
   ↓
6. Results broadcast via PubSub
   ↓
7. Frontend receives SSE updates
   ↓
8. UI updates in real-time
```

### Template Installation Flow

```
1. User uploads .jido.zip file
   ↓
2. Frontend sends multipart POST
   ↓
3. Agent Service extracts archive
   ↓
4. Validates jido-template.yaml
   ↓
5. Stores in ~/.jido/templates/
   ↓
6. Updates Template Registry
   ↓
7. Returns template metadata
```

## Security Architecture

### Defense in Depth

1. **Network Layer**
   - Loopback-only binding (127.0.0.1)
   - No external network access by default
   - Per-session bearer tokens

2. **Application Layer**
   - Tauri security configuration
   - Strict CSP headers
   - Command allowlisting

3. **Data Layer**
   - Secrets in OS Keychain
   - No plaintext credentials
   - Encrypted at rest

### Threat Model

```
┌─────────────────┐
│  Threat Actors  │
├─────────────────┤
│ • Local malware │
│ • Supply chain  │
│ • User mistakes │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│   Mitigations   │
├─────────────────┤
│ • Process isol. │
│ • Input valid.  │
│ • Least priv.   │
└─────────────────┘
```

## JIDO Framework Integration

### Agent Lifecycle

```elixir
TemplateRunner
  ↓
on_after_init/2
  ↓
plan/2 (generates actions)
  ↓
on_before_run_action/3
  ↓
run_action/2
  ↓
on_after_run_action/4
  ↓
decide/2 (next action or complete)
```

### Action Pipeline

```
1. Action Schema Validation
2. Pre-execution Hooks
3. Action Execution
4. Result Processing
5. Post-execution Hooks
6. State Update
7. Event Broadcasting
```

## Scalability Considerations

### Concurrent Execution
- Each run in separate process
- OTP supervision tree
- Fault isolation
- Resource limits per run

### Performance Optimization
- SSE for real-time updates
- Batch operations
- Lazy loading
- Client-side caching

## Technology Stack

### Core Technologies
- **Tauri 2.0**: Desktop framework
- **React 18**: UI framework
- **TypeScript 5**: Type safety
- **Elixir 1.16**: Backend language
- **JIDO 1.0.0**: Agent framework
- **Phoenix**: Web framework
- **SQLite/PostgreSQL**: Database

### Supporting Libraries
- **shadcn/ui**: Component library
- **Zustand**: State management
- **Tailwind CSS**: Styling
- **Bandit**: HTTP server
- **Ecto**: Database wrapper

## Deployment Architecture

### Development
```
Local Machine
├── Agent Service (Mix)
├── Tauri Dev Server (Vite)
└── Hot Module Replacement
```

### Production
```
Application Bundle
├── Tauri Binary
├── Embedded Agent Service
├── Templates Directory
└── Configuration Files
```

## Monitoring & Observability

### Metrics Collection
- Agent execution times
- Action success rates
- Token consumption
- Error frequencies

### Logging Strategy
- Structured JSON logs
- Log levels (debug/info/warn/error)
- Rotating file logs
- Real-time streaming

### Health Checks
- Service availability
- Database connectivity
- External service status
- Resource utilization