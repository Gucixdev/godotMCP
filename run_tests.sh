#!/bin/bash

# Automated test script for Godot MCP Server
# Tests the Python server without requiring Godot to be running

set -e

echo "======================================================"
echo "  Godot MCP Server - Automated Test"
echo "======================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed${NC}"
    exit 1
fi

# Check if requirements are installed
echo -e "${YELLOW}[1/5] Checking dependencies...${NC}"
if ! python3 -c "import websockets" 2>/dev/null; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    pip install -r requirements.txt
fi
echo -e "${GREEN}✓ Dependencies OK${NC}"
echo ""

# Start Python server in background
echo -e "${YELLOW}[2/5] Starting Python MCP Server...${NC}"
python3 godot_mcp_server.py --log-level WARNING > server.log 2>&1 &
SERVER_PID=$!

# Save PID for cleanup
echo $SERVER_PID > .server.pid

# Function to cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}[5/5] Cleaning up...${NC}"
    if [ -f .server.pid ]; then
        SERVER_PID=$(cat .server.pid)
        if ps -p $SERVER_PID > /dev/null 2>&1; then
            kill $SERVER_PID 2>/dev/null || true
            echo -e "${GREEN}✓ Server stopped${NC}"
        fi
        rm .server.pid
    fi
}

trap cleanup EXIT INT TERM

# Wait for server to start
echo -e "${YELLOW}Waiting for server to start...${NC}"
sleep 2

# Check if server is running
if ! ps -p $SERVER_PID > /dev/null; then
    echo -e "${RED}✗ Server failed to start${NC}"
    echo "Server log:"
    cat server.log
    exit 1
fi
echo -e "${GREEN}✓ Server started (PID: $SERVER_PID)${NC}"
echo ""

# Test connection
echo -e "${YELLOW}[3/5] Testing server connection...${NC}"
if ! nc -z localhost 8765 2>/dev/null; then
    # If nc is not available, try with Python
    if ! python3 -c "import socket; s=socket.socket(); s.settimeout(1); s.connect(('localhost', 8765)); s.close()" 2>/dev/null; then
        echo -e "${RED}✗ Cannot connect to server on port 8765${NC}"
        echo "Server log:"
        tail -20 server.log
        exit 1
    fi
fi
echo -e "${GREEN}✓ Server is listening on localhost:8765${NC}"
echo ""

# Run test client
echo -e "${YELLOW}[4/5] Running test client...${NC}"
echo "======================================================"
echo ""

if python3 test_client.py; then
    echo ""
    echo "======================================================"
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo "======================================================"
    echo ""
    echo "The Python MCP server is working correctly!"
    echo ""
    echo "Next steps:"
    echo "1. Open Godot 4.5: godot project.godot"
    echo "2. Check Output panel for connection status"
    echo "3. Send commands from external tools"
    echo ""
    exit 0
else
    echo ""
    echo "======================================================"
    echo -e "${RED}✗ TESTS FAILED${NC}"
    echo "======================================================"
    echo ""
    echo "Check server.log for details"
    exit 1
fi
