# Godot MCP Server

A fully functional **Model Context Protocol (MCP)** WebSocket server for **Godot 4.5**, built with Python 3.9+.

## Overview

This server implements the Model Context Protocol to enable communication with Godot 4.5 editor through WebSocket connections. It receives MCP commands, logs them, and returns properly formatted JSON responses.

## Features

- **WebSocket Server**: Asynchronous WebSocket server using `websockets` library
- **Full MCP Support**: Handles 10 core MCP commands for Godot interaction
- **Comprehensive Logging**: Logs all requests and responses to file and console
- **Command-line Configuration**: Flexible port and host configuration
- **Error Handling**: Robust error handling with detailed error responses

## Requirements

- Python 3.9 or higher
- websockets library (12.0+)

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd godotMCP
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## Usage

### Basic Usage

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

## Integration with Godot

This server is designed to work with a Godot 4.5 plugin that:
1. Connects to this WebSocket server
2. Receives MCP commands
3. Executes them within the Godot editor
4. Returns results back through the WebSocket

## Development

The codebase structure:
- `godot_mcp_server.py`: Main server implementation
- `requirements.txt`: Python dependencies
- `README.md`: This documentation

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
