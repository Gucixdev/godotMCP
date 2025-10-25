# Testing Guide

Complete guide for testing the Godot MCP implementation.

## Quick Test

The fastest way to verify everything works:

```bash
# 1. Verify setup
python verify_setup.py

# 2. Run automated tests
bash run_tests.sh
```

## Manual Testing

### Step 1: Verify Setup

Check if everything is configured correctly:

```bash
python verify_setup.py
```

This will check:
- ✅ Python version (3.9+)
- ✅ Dependencies (websockets)
- ✅ All project files
- ✅ Godot installation (optional)
- ✅ Port 8765 availability

**Expected output:**
```
📋 VERIFICATION SUMMARY
  ✅ PASS - Python Version
  ✅ PASS - Dependencies
  ✅ PASS - Project Files
  ✅ PASS - Godot Installation
  ✅ PASS - Port Availability
```

### Step 2: Test Python Server Standalone

Test the Python server without Godot:

```bash
# Terminal 1: Start server
python godot_mcp_server.py

# Terminal 2: Run test client
python test_client.py
```

**Expected output (Terminal 1):**
```
Starting Godot MCP Server on localhost:8765
Server is running and listening on ws://localhost:8765
New client connected: 127.0.0.1:xxxxx
Received from 127.0.0.1:xxxxx: {
  "id": "test-001",
  "command": "GetProjectInfo",
  "params": {}
}
```

**Expected output (Terminal 2):**
```
Connecting to ws://localhost:8765...
Connected successfully!

============================================================
Sending: GetProjectInfo
Request ID: test-001
Parameters: {}
============================================================

Response:
{
  "id": "test-001",
  "status": "success",
  ...
}
```

### Step 3: Test Godot Integration

Test with actual Godot editor:

```bash
# Terminal 1: Start Python server
python godot_mcp_server.py

# Terminal 2: Open Godot
godot project.godot
```

**Check Godot Output panel:**
```
[Godot MCP] Plugin enabled
[MCP Client] Connecting to ws://localhost:8765...
[MCP Client] Connection initiated
[MCP Client] Connected to ws://localhost:8765
```

**Check Python server output:**
```
New client connected: 127.0.0.1:xxxxx
```

### Step 4: Send Real Commands

With Godot open and connected, send commands:

```bash
# Terminal 3: Send a command
python test_client.py
```

Now watch the responses change! When Godot is connected, you'll see **real data** instead of mock responses:

**GetProjectInfo with Godot connected:**
```json
{
  "data": {
    "project_name": "Godot MCP",
    "godot_version": "4.5.stable",
    "project_path": "/actual/path/to/godotMCP/"
  }
}
```

## Automated Testing

### Full Test Suite

Run all tests automatically:

```bash
bash run_tests.sh
```

This script will:
1. ✅ Check dependencies
2. ✅ Start Python server
3. ✅ Test connection
4. ✅ Run all 10 MCP commands
5. ✅ Clean up automatically

**Expected output:**
```
======================================================
  Godot MCP Server - Automated Test
======================================================

[1/5] Checking dependencies...
✓ Dependencies OK

[2/5] Starting Python MCP Server...
✓ Server started (PID: 12345)

[3/5] Testing server connection...
✓ Server is listening on localhost:8765

[4/5] Running test client...
... (test output) ...

✓ ALL TESTS PASSED
```

## Testing Individual Commands

### Test GetProjectInfo

```python
import asyncio
import websockets
import json

async def test():
    async with websockets.connect("ws://localhost:8765") as ws:
        await ws.send(json.dumps({
            "id": "1",
            "command": "GetProjectInfo",
            "params": {}
        }))
        print(await ws.recv())

asyncio.run(test())
```

### Test AddNode (Requires Godot + Open Scene)

```python
import asyncio
import websockets
import json

async def test():
    async with websockets.connect("ws://localhost:8765") as ws:
        await ws.send(json.dumps({
            "id": "2",
            "command": "AddNode",
            "params": {
                "parent_path": "",
                "node_type": "Node2D",
                "node_name": "TestNode"
            }
        }))
        response = json.loads(await ws.recv())
        print(f"Status: {response['status']}")
        print(f"Node path: {response['data']['node_path']}")

asyncio.run(test())
```

Check Godot's scene tree - you should see the new node!

## Common Test Scenarios

### Scenario 1: File Operations

```bash
# Create a test script
echo 'extends Node' > test_script.gd

# Get its content via MCP
python -c "
import asyncio, websockets, json
async def test():
    async with websockets.connect('ws://localhost:8765') as ws:
        await ws.send(json.dumps({
            'command': 'GetFileContent',
            'params': {'file_path': 'res://test_script.gd'}
        }))
        print(await ws.recv())
asyncio.run(test())
"
```

### Scenario 2: Scene Manipulation

1. Open a scene in Godot
2. Run test_client.py
3. Check that nodes are actually added/removed in the scene tree

### Scenario 3: Property Manipulation

1. Add a Sprite2D node manually in Godot
2. Use SetNodeProperty to change its position:

```python
{
  "command": "SetNodeProperty",
  "params": {
    "node_path": "Sprite2D",
    "property_name": "position",
    "property_value": {"x": 100, "y": 200}
  }
}
```

3. Watch the sprite move in the editor!

## Performance Testing

### Connection Latency

```bash
# Measure round-trip time
time python -c "
import asyncio, websockets, json
async def test():
    async with websockets.connect('ws://localhost:8765') as ws:
        await ws.send(json.dumps({'command': 'GetProjectInfo', 'params': {}}))
        await ws.recv()
asyncio.run(test())
"
```

Typical latency: < 10ms on localhost

### Stress Test

Send 100 commands rapidly:

```python
import asyncio
import websockets
import json
import time

async def stress_test():
    async with websockets.connect("ws://localhost:8765") as ws:
        start = time.time()

        for i in range(100):
            await ws.send(json.dumps({
                "id": f"stress-{i}",
                "command": "GetProjectInfo",
                "params": {}
            }))
            await ws.recv()

        elapsed = time.time() - start
        print(f"100 requests in {elapsed:.2f}s")
        print(f"Average: {(elapsed/100)*1000:.2f}ms per request")

asyncio.run(stress_test())
```

## Troubleshooting Tests

### Server Won't Start

```bash
# Check if port is in use
lsof -i :8765

# Or use different port
python godot_mcp_server.py --port 9000
```

### Connection Refused

```bash
# Verify server is running
ps aux | grep godot_mcp_server

# Check server logs
cat godot_mcp_server.log
```

### Godot Plugin Not Connecting

1. Check Output panel in Godot for errors
2. Verify plugin is enabled: Project → Project Settings → Plugins
3. Check host/port in `addons/godot_mcp/plugin.gd`
4. Restart Godot

### Commands Not Executing

**If commands are logged but nothing happens:**

1. Ensure a scene is open in Godot (required for node operations)
2. Check Godot Output panel for error messages
3. Verify the node/file paths are correct

**If getting "not found" errors:**

- Use `res://` prefix for file paths
- Use relative node paths (e.g., "Sprite2D" not "/root/Sprite2D")
- Ensure parent nodes exist before adding children

## Test Coverage

| Command | Test Status | Notes |
|---------|------------|-------|
| GetProjectInfo | ✅ Tested | Returns real project data when Godot connected |
| GetFileContent | ✅ Tested | Reads actual files from res:// |
| SetFileContent | ✅ Tested | Writes files and refreshes filesystem |
| GetSceneNodes | ✅ Tested | Loads and parses .tscn files |
| AddNode | ✅ Tested | Creates nodes in open scene |
| RemoveNode | ✅ Tested | Removes nodes from scene tree |
| GetNodeProperty | ✅ Tested | Reads properties with serialization |
| SetNodeProperty | ✅ Tested | Sets properties with type conversion |
| FindAllFilesByType | ✅ Tested | Recursive directory scanning |
| RunToolMethod | ✅ Tested | Custom tool methods |

## Continuous Testing

### Pre-commit Hook

```bash
# .git/hooks/pre-commit
#!/bin/bash
python verify_setup.py || exit 1
```

### CI/CD Integration

```yaml
# .github/workflows/test.yml
name: Test MCP Server
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.9'
      - run: pip install -r requirements.txt
      - run: python verify_setup.py
      - run: bash run_tests.sh
```

## Next Steps

After successful testing:

1. ✅ Read [INSTALLATION.md](INSTALLATION.md) for deployment
2. ✅ Read [README.md](README.md) for usage examples
3. ✅ Integrate with your external tools
4. ✅ Customize tool methods in `mcp_executor.gd`

## Support

If tests fail:
- Check `godot_mcp_server.log` for server errors
- Check Godot Output panel for plugin errors
- Review troubleshooting sections in INSTALLATION.md
- Open an issue with test output
