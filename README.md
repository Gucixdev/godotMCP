# Godot MCP Server

A fully functional **Model Context Protocol (MCP)** integration for **Godot 4.5**, combining a Python WebSocket server with a GDScript editor plugin.

## Overview

This project provides complete MCP support for Godot 4.5 through a two-part architecture:

1. **Python WebSocket Server** - Acts as the MCP protocol bridge, receives commands from external tools
2. **Godot Editor Plugin (GDScript)** - Executes commands within Godot using the Editor API

External tools communicate with the Python server, which forwards commands to the Godot plugin via WebSocket. The plugin executes operations in the Godot editor and returns results.

## Architecture

```
[External Tool] → [Python MCP Server] ←WebSocket→ [Godot Editor Plugin] → [Godot API]
```

## Features

### Python Server
- **WebSocket Server**: Asynchronous WebSocket server using `websockets` library
- **MCP Protocol**: Handles 10 core MCP commands
- **Comprehensive Logging**: Logs all requests and responses to file and console
- **Command-line Configuration**: Flexible port and host configuration
- **Error Handling**: Robust error handling with detailed JSON responses

### Godot Plugin
- **Editor Integration**: Full EditorPlugin with WebSocket client
- **Real Command Execution**: Actually performs operations in Godot (not simulation)
- **Scene Manipulation**: Add/remove nodes, get/set properties
- **File Operations**: Read/write project files with filesystem refresh
- **Project Info**: Access real project settings and Godot version

## Requirements

- Python 3.9 or higher
- Godot 4.5
- websockets library (12.0+)

## Quick Start

See [INSTALLATION.md](INSTALLATION.md) for detailed setup instructions.

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Start Python Server

```bash
python godot_mcp_server.py
```

### 3. Open in Godot 4.5

```bash
godot project.godot
```

The Godot plugin will auto-connect to the Python server. Check the Output panel for connection status.

## Usage

### Python Server

Start the server with default settings (localhost:8765):
```bash
python godot_mcp_server.py
```

### Custom Port

Specify a custom port:
```bash
python godot_mcp_server.py --port 9000
```

### Custom Host and Port

Bind to a specific host and port:
```bash
python godot_mcp_server.py --host 0.0.0.0 --port 8765
```

### Logging Levels

Set logging verbosity:
```bash
python godot_mcp_server.py --log-level DEBUG
```

### Command-line Arguments

- `--host`: Host address to bind (default: localhost)
- `--port`: Port number to bind (default: 8765)
- `--log-level`: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)

## Supported MCP Commands

The server supports the following Model Context Protocol commands:

### 1. GetProjectInfo
Get information about the Godot project.

**Request:**
```json
{
  "id": "req-001",
  "command": "GetProjectInfo",
  "params": {}
}
```

**Response:**
```json
{
  "id": "req-001",
  "status": "success",
  "timestamp": "2025-10-25T12:00:00.000000",
  "data": {
    "command": "GetProjectInfo",
    "project_name": "GodotMCPProject",
    "godot_version": "4.5",
    "project_path": "/path/to/project",
    "message": "Project info retrieved successfully"
  }
}
```

### 2. GetFileContent
Retrieve content of a file from the project.

**Request:**
```json
{
  "id": "req-002",
  "command": "GetFileContent",
  "params": {
    "file_path": "res://scripts/player.gd"
  }
}
```

### 3. SetFileContent
Set or update content of a file in the project.

**Request:**
```json
{
  "id": "req-003",
  "command": "SetFileContent",
  "params": {
    "file_path": "res://scripts/player.gd",
    "content": "extends CharacterBody2D\n..."
  }
}
```

### 4. GetSceneNodes
Get all nodes from a scene file.

**Request:**
```json
{
  "id": "req-004",
  "command": "GetSceneNodes",
  "params": {
    "scene_path": "res://scenes/main.tscn"
  }
}
```

### 5. AddNode
Add a new node to a scene.

**Request:**
```json
{
  "id": "req-005",
  "command": "AddNode",
  "params": {
    "parent_path": "Root",
    "node_type": "Sprite2D",
    "node_name": "PlayerSprite"
  }
}
```

### 6. RemoveNode
Remove a node from a scene.

**Request:**
```json
{
  "id": "req-006",
  "command": "RemoveNode",
  "params": {
    "node_path": "Root/PlayerSprite"
  }
}
```

### 7. GetNodeProperty
Get a property value from a node.

**Request:**
```json
{
  "id": "req-007",
  "command": "GetNodeProperty",
  "params": {
    "node_path": "Root/Player",
    "property_name": "position"
  }
}
```

### 8. SetNodeProperty
Set a property value on a node.

**Request:**
```json
{
  "id": "req-008",
  "command": "SetNodeProperty",
  "params": {
    "node_path": "Root/Player",
    "property_name": "position",
    "property_value": {"x": 100, "y": 200}
  }
}
```

### 9. FindAllFilesByType
Find all files of a specific type in the project.

**Request:**
```json
{
  "id": "req-009",
  "command": "FindAllFilesByType",
  "params": {
    "file_type": "gd",
    "search_path": "res://scripts"
  }
}
```

### 10. RunToolMethod
Execute a tool method in Godot.

**Request:**
```json
{
  "id": "req-010",
  "command": "RunToolMethod",
  "params": {
    "method_name": "build_project",
    "method_params": {}
  }
}
```

## Response Format

All responses follow this format:

**Success Response:**
```json
{
  "id": "request-id",
  "status": "success",
  "timestamp": "2025-10-25T12:00:00.000000",
  "data": {
    // Command-specific data
  }
}
```

**Error Response:**
```json
{
  "id": "request-id",
  "status": "error",
  "timestamp": "2025-10-25T12:00:00.000000",
  "error": "Error description"
}
```

## Logging

The server logs all activity to:
- **Console**: Real-time output
- **File**: `godot_mcp_server.log` in the working directory

Log format includes:
- Timestamp
- Log level
- Component name
- Message

## Architecture

The server is built with:
- **asyncio**: Python's asynchronous I/O framework
- **websockets**: WebSocket server implementation
- **JSON**: Request/response serialization
- **logging**: Comprehensive activity logging

## Testing

You can test the server using any WebSocket client. Example with `websocat`:

```bash
websocat ws://localhost:8765
```

Then send a JSON command:
```json
{"id": "test-1", "command": "GetProjectInfo", "params": {}}
```

## How It Works

### Integration Flow

1. **External Tool** sends MCP command to Python server (e.g., "AddNode")
2. **Python Server** logs the command and forwards it to Godot via WebSocket
3. **Godot Plugin** receives the command through its WebSocket client
4. **MCP Executor** executes the command using Godot's Editor API
5. **Result** flows back through the same path to the external tool

### Example: Adding a Node

**External tool sends:**
```json
{
  "command": "AddNode",
  "params": {
    "parent_path": "Root",
    "node_type": "Sprite2D",
    "node_name": "Player"
  }
}
```

**Python server** logs and forwards to Godot

**Godot plugin** executes:
```gdscript
var new_node = Sprite2D.new()
new_node.name = "Player"
parent.add_child(new_node)
```

**Response returned:**
```json
{
  "status": "success",
  "data": {
    "node_path": "Root/Player",
    "message": "Node Player added successfully"
  }
}
```

## Development

### Project Structure

```
godotMCP/
├── Python Server
│   ├── godot_mcp_server.py     # WebSocket server (MCP bridge)
│   ├── test_client.py          # Test utility
│   └── requirements.txt        # Python dependencies
│
├── Godot Plugin
│   └── addons/godot_mcp/
│       ├── plugin.cfg          # Plugin metadata
│       ├── plugin.gd           # EditorPlugin (entry point)
│       ├── mcp_client.gd       # WebSocket client (connects to Python)
│       └── mcp_executor.gd     # Command executor (uses Godot API)
│
├── Documentation
│   ├── README.md               # This file
│   └── INSTALLATION.md         # Detailed setup guide
│
└── project.godot               # Godot project file
```

### Code Overview

**Python Server (`godot_mcp_server.py`)**
- WebSocket server using `asyncio` and `websockets`
- Receives MCP commands, logs them
- Routes commands to connected Godot clients
- Returns responses to external tools

**Godot Plugin (`addons/godot_mcp/`)**
- `plugin.gd`: Main EditorPlugin, manages lifecycle
- `mcp_client.gd`: WebSocket client, handles communication
- `mcp_executor.gd`: Executes commands using Godot Editor API

### Implementation Details

All 10 MCP commands are implemented in `mcp_executor.gd`:

| Command | Implementation |
|---------|---------------|
| GetProjectInfo | Uses `ProjectSettings` and `Engine.get_version_info()` |
| GetFileContent | `FileAccess.open()` with `res://` paths |
| SetFileContent | `FileAccess.open()` + `EditorFileSystem.scan()` |
| GetSceneNodes | `ResourceLoader.load()` + recursive tree walk |
| AddNode | `ClassDB.instantiate()` + `add_child()` |
| RemoveNode | `get_node()` + `queue_free()` |
| GetNodeProperty | `node.get()` with serialization |
| SetNodeProperty | `node.set()` with deserialization |
| FindAllFilesByType | `DirAccess` recursive directory scan |
| RunToolMethod | Custom tool methods (build, reload, save) |

## License

This project is open source and available under standard licensing terms.

## Contributing

Contributions are welcome! Please ensure:
- Code follows Python PEP 8 style guidelines
- All new commands include proper logging
- Documentation is updated for new features

## Troubleshooting

### Port Already in Use
If you get a "port already in use" error, either:
- Stop the process using that port
- Choose a different port with `--port`

### Connection Refused
Ensure:
- Server is running
- Firewall allows connections on the specified port
- WebSocket client is connecting to correct host:port

### Invalid JSON Errors
Verify that:
- Request is valid JSON
- Required fields (`command`, `id`) are present
- Parameter format matches command specification

## Contact

For issues, questions, or contributions, please open an issue on the repository.
