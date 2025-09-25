#!/bin/bash

# JIDO Conductor Development Runner Script
# Starts both the agent service and Tauri app in development mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    
    # Kill agent service if running
    if [ ! -z "$AGENT_PID" ]; then
        kill $AGENT_PID 2>/dev/null || true
    fi
    
    # Kill Tauri dev server if running
    if [ ! -z "$TAURI_PID" ]; then
        kill $TAURI_PID 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓ Services stopped${NC}"
    exit 0
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     JIDO Conductor Development Mode    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Check if agent_service directory exists
if [ ! -d "agent_service" ]; then
    echo -e "${RED}Error: agent_service directory not found${NC}"
    echo "Please run this script from the project root"
    exit 1
fi

# Check if app directory exists
if [ ! -d "app" ]; then
    echo -e "${RED}Error: app directory not found${NC}"
    echo "Please run this script from the project root"
    exit 1
fi

# Check for package manager
if command -v bun &> /dev/null; then
    PKG_MANAGER="bun"
elif command -v npm &> /dev/null; then
    PKG_MANAGER="npm"
else
    echo -e "${RED}❌ No Node.js package manager found${NC}"
    exit 1
fi

# Start agent service
echo -e "\n${YELLOW}Starting Agent Service on port 8745...${NC}"
cd agent_service
mix phx.server &
AGENT_PID=$!
cd ..

# Wait for agent service to be ready
echo -e "${YELLOW}Waiting for agent service to be ready...${NC}"
sleep 3

# Check if agent service is running
if ! curl -s http://127.0.0.1:8745 > /dev/null 2>&1; then
    echo -e "${YELLOW}Waiting a bit more for agent service...${NC}"
    sleep 5
fi

if curl -s http://127.0.0.1:8745 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Agent service is running${NC}"
else
    echo -e "${RED}⚠ Agent service might not be fully ready yet${NC}"
fi

# Start Tauri app
echo -e "\n${YELLOW}Starting Tauri Desktop App...${NC}"
cd app
$PKG_MANAGER run tauri:dev &
TAURI_PID=$!
cd ..

echo -e "\n${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN} Development environment is running!${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "\n${YELLOW}Services:${NC}"
echo -e "  • Agent Service: ${BLUE}http://127.0.0.1:8745${NC}"
echo -e "  • Tauri App: Starting..."
echo -e "\n${YELLOW}Press Ctrl+C to stop all services${NC}\n"

# Wait for processes
wait