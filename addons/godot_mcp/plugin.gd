@tool
extends EditorPlugin

## Godot MCP Plugin - Main EditorPlugin class
## Manages the MCP client connection and integration with Godot editor

var mcp_client: Node
var mcp_executor: Node

const DEFAULT_HOST := "localhost"
const DEFAULT_PORT := 8765

func _enter_tree() -> void:
	print("[Godot MCP] Plugin enabled")

	# Create MCP executor (handles actual Godot operations)
	mcp_executor = preload("res://addons/godot_mcp/mcp_executor.gd").new()
	mcp_executor.editor_plugin = self
	add_child(mcp_executor)

	# Create MCP client (WebSocket connection)
	mcp_client = preload("res://addons/godot_mcp/mcp_client.gd").new()
	mcp_client.executor = mcp_executor
	add_child(mcp_client)

	# Auto-connect on startup
	mcp_client.connect_to_server(DEFAULT_HOST, DEFAULT_PORT)

func _exit_tree() -> void:
	print("[Godot MCP] Plugin disabled")

	if mcp_client:
		mcp_client.disconnect_from_server()
		mcp_client.queue_free()

	if mcp_executor:
		mcp_executor.queue_free()

func _get_plugin_name() -> String:
	return "Godot MCP"
