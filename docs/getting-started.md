# Getting Started with JIDO Conductor

## Prerequisites

Before installing JIDO Conductor, ensure you have the following installed:

- **Rust** (1.70+) - [Install Rust](https://rustup.rs/)
- **Node.js** (20+) - [Install Node.js](https://nodejs.org/)
- **Elixir** (1.16+) - [Install Elixir](https://elixir-lang.org/install.html)
- **Claude Code CLI** - [Install Claude Code](https://github.com/anthropics/claude-code)

## Installation

### From Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/jido-conductor.git
cd jido-conductor/.conductor/islamabad
```

2. Install dependencies:
```bash
# Frontend dependencies
cd app
bun install  # or npm install

# Backend dependencies
cd ../agent_service
mix deps.get
```

3. Build the application:
```bash
# Development build
cd app
bun run tauri dev

# Production build
bun run tauri build
```

### From Release

Download the latest release for your platform from the [Releases page](https://github.com/yourusername/jido-conductor/releases).

## First Run

1. **Start the Agent Service**:
```bash
cd agent_service
mix phx.server
```
The service will start on `http://127.0.0.1:8745`

2. **Launch the Desktop App**:
   - Development: `cd app && bun run tauri dev`
   - Production: Run the installed application

3. **Configure Claude Code**:
   - Open Settings in the app
   - Add your Claude API key
   - Test the connection

## Creating Your First Agent

1. Navigate to the Templates section
2. Click "Create New Template"
3. Fill in the template details:
   - Name: "My First Agent"
   - Description: "A simple test agent"
   - Version: "1.0.0"
4. Configure the agent actions
5. Save the template

## Running an Agent

1. Go to the Runs section
2. Select your template
3. Configure run parameters
4. Click "Start Run"
5. Monitor the execution in real-time

## Next Steps

- [Read the User Guide](./user-guide.md)
- [Learn about Template Development](./template-development.md)
- [Explore the API](./api-reference.md)