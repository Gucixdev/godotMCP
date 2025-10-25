# Godot MCP - Installation Guide

Complete setup guide for the Godot Model Context Protocol integration.

## Architecture Overview

The Godot MCP system consists of two components:

1. **Python WebSocket Server** (`godot_mcp_server.py`)
   - Acts as the MCP protocol bridge
   - Receives commands from external tools
   - Forwards them to Godot via WebSocket
   - Logs all communication

2. **Godot Editor Plugin** (`addons/godot_mcp/`)
   - Runs inside Godot 4.5 editor
   - Connects to Python server via WebSocket
   - Executes actual commands using Godot API
   - Returns results back to server

## Prerequisites

- **Python 3.9+**
- **Godot 4.5**
- **websockets** Python library

## Installation Steps

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Start the Python MCP Server

```bash
# Default (localhost:8765)
python godot_mcp_server.py

# Custom port
python godot_mcp_server.py --port 9000

# Custom host and port
python godot_mcp_server.py --host 0.0.0.0 --port 8765

# Debug mode
python godot_mcp_server.py --log-level DEBUG
```

The server will start and wait for connections:
```
Starting Godot MCP Server on localhost:8765
Server is running and listening on ws://localhost:8765
```

### 3. Open Project in Godot 4.5

```bash
# From project directory
godot project.godot
```

Or use the Godot Project Manager:
1. Click "Import"
2. Navigate to this directory
3. Select `project.godot`
4. Click "Import & Edit"

### 4. Enable the Plugin

The plugin should auto-enable, but if not:

1. Go to **Project → Project Settings**
2. Navigate to the **Plugins** tab
3. Find **Godot MCP** in the list
4. Click the checkbox to enable it

### 5. Verify Connection

Check the Godot Output panel (bottom). You should see:

```
[Godot MCP] Plugin enabled
[MCP Client] Connecting to ws://localhost:8765...
[MCP Client] Connection initiated
[MCP Client] Connected to ws://localhost:8765
```

And in the Python server console:

```
New client connected: 127.0.0.1:xxxxx
```

## Configuration

### Python Server

Edit connection settings in `addons/godot_mcp/plugin.gd`:

```gdscript
const DEFAULT_HOST := "localhost"
const DEFAULT_PORT := 8765
```

### Godot Plugin

The plugin auto-connects on startup. To manually control:

```gdscript
# In plugin.gd
func _enter_tree() -> void:
    # ...
    # Comment out auto-connect to disable:
    # mcp_client.connect_to_server(DEFAULT_HOST, DEFAULT_PORT)
```

## Testing the Integration

### Method 1: Use the Test Client

```bash
python test_client.py
```

This will send all 10 MCP commands to the server, which forwards them to Godot.

### Method 2: Manual Testing with WebSocket Client

Using `websocat` or similar:

```bash
websocat ws://localhost:8765
```

Send a command:

```json
{
  "id": "test-1",
  "command": "GetProjectInfo",
  "params": {}
}
```

You should receive a response with actual Godot project data:

```json
{
  "id": "test-1",
  "status": "success",
  "timestamp": "2025-10-25T12:00:00",
  "data": {
    "command": "GetProjectInfo",
    "project_name": "Godot MCP",
    "godot_version": "4.5.stable",
    "project_path": "/path/to/godotMCP/",
    "message": "Project info retrieved successfully"
  }
}
```

## Using in Your Own Project

To add MCP support to an existing Godot project:

1. Copy the `addons/godot_mcp/` directory to your project
2. Enable the plugin in Project Settings
3. Start the Python server
4. The plugin will auto-connect

## Troubleshooting

### Plugin Not Loading

**Error**: Plugin script not found

**Solution**: Ensure the path in `project.godot` is correct:

```ini
[editor_plugins]
enabled=PackedStringArray("res://addons/godot_mcp/plugin.gd")
```

### Connection Failed

**Error**: `[MCP Client] Failed to connect`

**Solution**:
- Ensure Python server is running
- Check host/port match in both server and plugin
- Verify firewall isn't blocking the connection

### Commands Not Executing

**Error**: Commands are logged but nothing happens in Godot

**Solution**:
- Check Godot Output panel for errors
- Ensure a scene is open in the editor (required for node operations)
- Verify the plugin is enabled

### Permission Errors

**Error**: `Failed to open file for writing`

**Solution**:
- Ensure Godot project is not read-only
- Check file paths use `res://` protocol
- Verify target directories exist

## Advanced Usage

### Custom Tool Methods

Add custom functionality by editing `mcp_executor.gd`:

```gdscript
func _run_tool_method(params: Dictionary, request_id: String) -> Dictionary:
    match method_name:
        "my_custom_method":
            result = _my_custom_implementation()
```

### Multiple Godot Instances

Run multiple Godot instances on different servers:

**Instance 1:**
```bash
python godot_mcp_server.py --port 8765
```

**Instance 2:**
```bash
python godot_mcp_server.py --port 8766
```

Then modify each Godot project's `plugin.gd` with the correct port.

### Remote Access

To allow external connections:

```bash
python godot_mcp_server.py --host 0.0.0.0 --port 8765
```

**Warning**: This exposes the server to your network. Use firewall rules for security.

## File Structure

```
godotMCP/
├── addons/
│   └── godot_mcp/
│       ├── plugin.cfg           # Plugin metadata
│       ├── plugin.gd            # EditorPlugin entry point
│       ├── mcp_client.gd        # WebSocket client
│       └── mcp_executor.gd      # Command executor (Godot API)
├── godot_mcp_server.py          # Python WebSocket server
├── test_client.py               # Test utility
├── requirements.txt             # Python dependencies
├── project.godot                # Godot project file
└── README.md                    # Main documentation
```

## Uninstallation

1. Disable the plugin in Godot Project Settings
2. Delete the `addons/godot_mcp/` directory
3. Stop the Python server (Ctrl+C)
4. Remove Python dependencies (optional):
   ```bash
   pip uninstall websockets
   ```

## Support

For issues or questions:
- Check the main [README.md](README.md) for command reference
- Review the [troubleshooting section](#troubleshooting)
- Open an issue on the repository
