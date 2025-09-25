#!/bin/bash

# JIDO Conductor Development Setup Script

set -e

echo "🚀 Setting up JIDO Conductor development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for required tools
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        echo "Please install $1 and run this script again"
        echo "Installation guide: $2"
        exit 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
    fi
}

echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check Rust
check_command "cargo" "https://rustup.rs/"

# Check Node.js
check_command "node" "https://nodejs.org/"

# Check Elixir
check_command "elixir" "https://elixir-lang.org/install.html"

# Check Mix
check_command "mix" "https://elixir-lang.org/install.html"

# Check for package manager (prefer bun, fallback to npm)
if command -v bun &> /dev/null; then
    PKG_MANAGER="bun"
    echo -e "${GREEN}✓ Using bun as package manager${NC}"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
    echo -e "${GREEN}✓ Using npm as package manager${NC}"
else
    echo -e "${RED}❌ No Node.js package manager found${NC}"
    echo "Please install bun or npm"
    exit 1
fi

# Setup Elixir dependencies
echo -e "\n${YELLOW}Setting up Elixir dependencies...${NC}"
cd agent_service

# Install Hex and Rebar
mix local.hex --force
mix local.rebar --force

# Get dependencies
mix deps.get
mix deps.compile

# Create and migrate database
echo -e "\n${YELLOW}Setting up database...${NC}"
mix ecto.create
mix ecto.migrate

cd ..

# Setup frontend dependencies
echo -e "\n${YELLOW}Setting up frontend dependencies...${NC}"
cd app

if [ "$PKG_MANAGER" = "bun" ]; then
    bun install
else
    npm install
fi

# Install Tauri CLI if not present
if ! command -v tauri &> /dev/null; then
    echo -e "\n${YELLOW}Installing Tauri CLI...${NC}"
    if [ "$PKG_MANAGER" = "bun" ]; then
        bun add -D @tauri-apps/cli
    else
        npm install -D @tauri-apps/cli
    fi
fi

cd ..

# Setup pre-commit hooks (if Python is available)
if command -v python3 &> /dev/null && command -v pip3 &> /dev/null; then
    echo -e "\n${YELLOW}Setting up pre-commit hooks...${NC}"
    pip3 install --user pre-commit
    pre-commit install
    echo -e "${GREEN}✓ Pre-commit hooks installed${NC}"
else
    echo -e "${YELLOW}⚠ Python not found, skipping pre-commit hooks setup${NC}"
    echo "To enable pre-commit hooks, install Python and run: pip install pre-commit && pre-commit install"
fi

# Create necessary directories
echo -e "\n${YELLOW}Creating necessary directories...${NC}"
mkdir -p ~/.jido/templates
mkdir -p ~/.jido/secrets

# Check for Claude Code CLI
if command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code CLI is installed${NC}"
else
    echo -e "${YELLOW}⚠ Claude Code CLI not found${NC}"
    echo "To enable agent execution, install Claude Code CLI:"
    echo "https://github.com/anthropics/claude-code"
fi

echo -e "\n${GREEN}🎉 Setup complete!${NC}"
echo -e "\n${YELLOW}To start the development environment:${NC}"
echo "1. Start the agent service:"
echo "   cd agent_service && mix phx.server"
echo ""
echo "2. In another terminal, start the desktop app:"
echo "   cd app && $PKG_MANAGER run tauri:dev"
echo ""
echo -e "${YELLOW}For more information, see docs/getting-started.md${NC}"