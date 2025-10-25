#!/bin/bash

# Setup script for Godot MCP - Creates virtual environment and installs dependencies

set -e

echo "======================================================"
echo "  Godot MCP - Setup Script"
echo "======================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Python version
echo -e "${YELLOW}[1/4] Checking Python version...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed${NC}"
    echo "Please install Python 3.9 or higher"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo -e "${GREEN}✓ Found Python ${PYTHON_VERSION}${NC}"

# Check if version is 3.9+
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
if [ "$PYTHON_MINOR" -lt 9 ]; then
    echo -e "${RED}Error: Python 3.9+ required, found 3.${PYTHON_MINOR}${NC}"
    exit 1
fi
echo ""

# Create virtual environment
echo -e "${YELLOW}[2/4] Creating virtual environment...${NC}"
if [ -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment already exists. Recreate? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf venv
        python3 -m venv venv
        echo -e "${GREEN}✓ Virtual environment recreated${NC}"
    else
        echo -e "${GREEN}✓ Using existing virtual environment${NC}"
    fi
else
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi
echo ""

# Activate virtual environment
echo -e "${YELLOW}[3/4] Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"
echo ""

# Install dependencies
echo -e "${YELLOW}[4/4] Installing dependencies...${NC}"
pip install --upgrade pip > /dev/null 2>&1
pip install -r requirements.txt
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Verify installation
echo "======================================================"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo "======================================================"
echo ""
echo "Virtual environment created at: ./venv"
echo ""
echo "To activate the virtual environment:"
echo -e "${YELLOW}  source venv/bin/activate${NC}"
echo ""
echo "To run the server:"
echo -e "${YELLOW}  python godot_mcp_server.py${NC}"
echo ""
echo "To run tests:"
echo -e "${YELLOW}  python verify_setup.py${NC}"
echo -e "${YELLOW}  bash run_tests.sh${NC}"
echo ""
echo "To deactivate when done:"
echo -e "${YELLOW}  deactivate${NC}"
echo ""

# Ask if user wants to run verification
echo -e "${YELLOW}Run setup verification now? (Y/n)${NC}"
read -r response
if [[ ! "$response" =~ ^[Nn]$ ]]; then
    echo ""
    python verify_setup.py
fi
