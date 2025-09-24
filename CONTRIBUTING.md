# Contributing to JIDO Conductor

We love your input! We want to make contributing to JIDO Conductor as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Pull Request Process

1. Update the README.md with details of changes to the interface, this includes new environment variables, exposed ports, useful file locations and container parameters.
2. Update the docs/ with any new functionality or API changes.
3. The PR will be merged once you have the sign-off of at least one other developer.

## Development Setup

### Prerequisites

- Rust 1.70+
- Node.js 20+
- Elixir 1.16+ & Erlang/OTP 26+
- Claude Code CLI (for agent execution)

### Setting Up Your Development Environment

```bash
# Clone your fork
git clone https://github.com/your-username/jido-conductor.git
cd jido-conductor/.conductor/islamabad

# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Frontend setup
cd app
bun install  # or npm install

# Backend setup
cd ../agent_service
mix deps.get
mix deps.compile
```

### Running the Development Environment

```bash
# Terminal 1: Start the agent service
cd agent_service
mix phx.server

# Terminal 2: Start the Tauri app
cd app
bun run tauri:dev
```

## Code Style

### Elixir

- Follow the official [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide)
- Use `mix format` before committing
- Run `mix credo --strict` for additional checks

### TypeScript/React

- We use ESLint and Prettier for code formatting
- Run `bun run lint` to check for linting errors
- Run `bun run format` to auto-format code

### Rust

- Follow the official [Rust Style Guide](https://doc.rust-lang.org/1.0.0/style/)
- Use `cargo fmt` before committing
- Run `cargo clippy` for additional checks

## Testing

### Elixir Tests

```bash
cd agent_service
mix test
```

### Frontend Tests

```bash
cd app
bun test
```

### Integration Tests

```bash
# Run the full test suite
./scripts/test.sh
```

## Project Structure

```
.conductor/islamabad/
├── app/                     # Tauri + React desktop application
│   ├── src/                # React source code
│   ├── src-tauri/         # Rust/Tauri backend
│   └── public/            # Static assets
├── agent_service/          # Elixir + JIDO agent service
│   ├── lib/               # Application code
│   ├── test/              # Tests
│   └── config/            # Configuration
├── templates/              # Agent templates
└── docs/                   # Documentation
```

## Key Components

### Frontend (React/TypeScript)

- **Components**: Reusable UI components in `app/src/components/`
- **Pages**: Route-based pages in `app/src/pages/`
- **Services**: API client and utilities in `app/src/services/`
- **Store**: Zustand state management in `app/src/store/`

### Backend (Elixir/JIDO)

- **Actions**: JIDO actions in `agent_service/lib/agent_service/actions/`
- **Agents**: JIDO agents in `agent_service/lib/agent_service/agents/`
- **Workflows**: JIDO workflows in `agent_service/lib/agent_service/workflows/`
- **API**: Phoenix controllers in `agent_service/lib/agent_service_web/controllers/`

## Commit Messages

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, etc)
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

Examples:
```
feat: add template import functionality
fix: resolve race condition in agent execution
docs: update API reference for runs endpoint
```

## Reporting Bugs

We use GitHub issues to track public bugs. Report a bug by [opening a new issue](https://github.com/yourusername/jido-conductor/issues/new).

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Feature Requests

We're always looking for suggestions to improve JIDO Conductor! If you have a feature request, please:

1. Check if the feature has already been requested in [Issues](https://github.com/yourusername/jido-conductor/issues)
2. If not, create a new issue with the `enhancement` label
3. Describe the feature and why it would be useful
4. Provide examples of how it would work

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Code of Conduct

### Our Pledge

We pledge to make participation in our project and community a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

Examples of behavior that contributes to creating a positive environment include:

- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

### Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported by contacting the project team. All complaints will be reviewed and investigated and will result in a response that is deemed necessary and appropriate to the circumstances.

## Questions?

Feel free to open an issue with your question or reach out to the maintainers directly.