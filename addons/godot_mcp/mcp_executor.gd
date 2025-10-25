extends Node

## MCP Command Executor
## Executes MCP commands using Godot Editor API

var editor_plugin: EditorPlugin = null
var editor_interface: EditorInterface = null
var editor_filesystem: EditorFileSystem = null

func _ready() -> void:
	if editor_plugin:
		editor_interface = editor_plugin.get_editor_interface()
		editor_filesystem = editor_interface.get_resource_filesystem()

func execute_command(command: String, params: Dictionary, request_id: String, client: Node) -> void:
	print("[MCP Executor] Executing command: %s" % command)

	var response: Dictionary

	match command:
		"GetProjectInfo":
			response = _get_project_info(params, request_id)
		"GetFileContent":
			response = _get_file_content(params, request_id)
		"SetFileContent":
			response = _set_file_content(params, request_id)
		"GetSceneNodes":
			response = _get_scene_nodes(params, request_id)
		"AddNode":
			response = _add_node(params, request_id)
		"RemoveNode":
			response = _remove_node(params, request_id)
		"GetNodeProperty":
			response = _get_node_property(params, request_id)
		"SetNodeProperty":
			response = _set_node_property(params, request_id)
		"FindAllFilesByType":
			response = _find_all_files_by_type(params, request_id)
		"RunToolMethod":
			response = _run_tool_method(params, request_id)
		_:
			response = _create_error_response(request_id, "Unknown command: %s" % command)

	client.send_response(response)

## ========== Helper Functions ==========

func _create_success_response(request_id: String, data: Dictionary) -> Dictionary:
	return {
		"id": request_id,
		"status": "success",
		"timestamp": Time.get_datetime_string_from_system(),
		"data": data
	}

func _create_error_response(request_id: String, error_message: String) -> Dictionary:
	return {
		"id": request_id,
		"status": "error",
		"timestamp": Time.get_datetime_string_from_system(),
		"error": error_message
	}

## ========== MCP Command Implementations ==========

func _get_project_info(_params: Dictionary, request_id: String) -> Dictionary:
	"""Get information about the Godot project"""
	var project_settings = ProjectSettings

	var data = {
		"command": "GetProjectInfo",
		"project_name": project_settings.get_setting("application/config/name", "Unknown"),
		"godot_version": Engine.get_version_info().string,
		"project_path": project_settings.globalize_path("res://"),
		"message": "Project info retrieved successfully"
	}

	return _create_success_response(request_id, data)

func _get_file_content(params: Dictionary, request_id: String) -> Dictionary:
	"""Read content from a file"""
	var file_path = params.get("file_path", "")

	if file_path == "":
		return _create_error_response(request_id, "Missing 'file_path' parameter")

	# Convert to absolute path if it's res://
	var abs_path = ProjectSettings.globalize_path(file_path)

	if not FileAccess.file_exists(file_path):
		return _create_error_response(request_id, "File not found: %s" % file_path)

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return _create_error_response(request_id, "Failed to open file: %s" % file_path)

	var content = file.get_as_text()
	file.close()

	var data = {
		"command": "GetFileContent",
		"file_path": file_path,
		"content": content,
		"message": "File content retrieved for: %s" % file_path
	}

	return _create_success_response(request_id, data)

func _set_file_content(params: Dictionary, request_id: String) -> Dictionary:
	"""Write content to a file"""
	var file_path = params.get("file_path", "")
	var content = params.get("content", "")

	if file_path == "":
		return _create_error_response(request_id, "Missing 'file_path' parameter")

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return _create_error_response(request_id, "Failed to open file for writing: %s" % file_path)

	file.store_string(content)
	file.close()

	# Refresh filesystem so Godot sees the changes
	if editor_filesystem:
		editor_filesystem.scan()

	var data = {
		"command": "SetFileContent",
		"file_path": file_path,
		"bytes_written": content.length(),
		"message": "File content set successfully for: %s" % file_path
	}

	return _create_success_response(request_id, data)

func _get_scene_nodes(params: Dictionary, request_id: String) -> Dictionary:
	"""Get all nodes from a scene file"""
	var scene_path = params.get("scene_path", "")

	if scene_path == "":
		return _create_error_response(request_id, "Missing 'scene_path' parameter")

	if not ResourceLoader.exists(scene_path):
		return _create_error_response(request_id, "Scene not found: %s" % scene_path)

	var packed_scene = ResourceLoader.load(scene_path)
	if not packed_scene or not packed_scene is PackedScene:
		return _create_error_response(request_id, "Failed to load scene: %s" % scene_path)

	var scene = packed_scene.instantiate()
	var nodes = _collect_nodes(scene, "")
	scene.free()

	var data = {
		"command": "GetSceneNodes",
		"scene_path": scene_path,
		"nodes": nodes,
		"message": "Scene nodes retrieved for: %s" % scene_path
	}

	return _create_success_response(request_id, data)

func _collect_nodes(node: Node, path: String) -> Array:
	"""Recursively collect all nodes from a node tree"""
	var nodes = []

	var node_path = path + "/" + node.name if path != "" else node.name
	var node_info = {
		"name": node.name,
		"type": node.get_class(),
		"path": node_path,
		"children": []
	}

	for child in node.get_children():
		var child_nodes = _collect_nodes(child, node_path)
		node_info["children"].append_array(child_nodes)

	nodes.append(node_info)
	return nodes

func _add_node(params: Dictionary, request_id: String) -> Dictionary:
	"""Add a new node to the currently edited scene"""
	var parent_path = params.get("parent_path", "")
	var node_type = params.get("node_type", "")
	var node_name = params.get("node_name", "")

	if node_type == "":
		return _create_error_response(request_id, "Missing 'node_type' parameter")
	if node_name == "":
		return _create_error_response(request_id, "Missing 'node_name' parameter")

	# Get current edited scene
	var edited_scene = editor_interface.get_edited_scene_root()
	if not edited_scene:
		return _create_error_response(request_id, "No scene is currently being edited")

	# Find parent node
	var parent_node: Node
	if parent_path == "" or parent_path == edited_scene.name:
		parent_node = edited_scene
	else:
		parent_node = edited_scene.get_node_or_null(parent_path)
		if not parent_node:
			return _create_error_response(request_id, "Parent node not found: %s" % parent_path)

	# Create new node
	var new_node: Node
	if ClassDB.class_exists(node_type):
		new_node = ClassDB.instantiate(node_type)
	else:
		return _create_error_response(request_id, "Unknown node type: %s" % node_type)

	if not new_node:
		return _create_error_response(request_id, "Failed to create node of type: %s" % node_type)

	new_node.name = node_name
	parent_node.add_child(new_node)
	new_node.owner = edited_scene

	# Mark scene as modified
	editor_interface.mark_scene_as_unsaved()

	var node_path = parent_node.get_path_to(new_node)

	var data = {
		"command": "AddNode",
		"parent_path": parent_path,
		"node_type": node_type,
		"node_name": node_name,
		"node_path": str(node_path),
		"message": "Node %s added successfully" % node_name
	}

	return _create_success_response(request_id, data)

func _remove_node(params: Dictionary, request_id: String) -> Dictionary:
	"""Remove a node from the currently edited scene"""
	var node_path = params.get("node_path", "")

	if node_path == "":
		return _create_error_response(request_id, "Missing 'node_path' parameter")

	var edited_scene = editor_interface.get_edited_scene_root()
	if not edited_scene:
		return _create_error_response(request_id, "No scene is currently being edited")

	var node = edited_scene.get_node_or_null(node_path)
	if not node:
		return _create_error_response(request_id, "Node not found: %s" % node_path)

	# Don't allow removing the root node
	if node == edited_scene:
		return _create_error_response(request_id, "Cannot remove the root node")

	node.queue_free()
	editor_interface.mark_scene_as_unsaved()

	var data = {
		"command": "RemoveNode",
		"node_path": node_path,
		"message": "Node %s removed successfully" % node_path
	}

	return _create_success_response(request_id, data)

func _get_node_property(params: Dictionary, request_id: String) -> Dictionary:
	"""Get a property value from a node"""
	var node_path = params.get("node_path", "")
	var property_name = params.get("property_name", "")

	if node_path == "":
		return _create_error_response(request_id, "Missing 'node_path' parameter")
	if property_name == "":
		return _create_error_response(request_id, "Missing 'property_name' parameter")

	var edited_scene = editor_interface.get_edited_scene_root()
	if not edited_scene:
		return _create_error_response(request_id, "No scene is currently being edited")

	var node = edited_scene.get_node_or_null(node_path)
	if not node:
		return _create_error_response(request_id, "Node not found: %s" % node_path)

	if not property_name in node:
		return _create_error_response(request_id, "Property '%s' not found in node" % property_name)

	var property_value = node.get(property_name)

	# Convert to JSON-serializable format
	var serialized_value = _serialize_value(property_value)

	var data = {
		"command": "GetNodeProperty",
		"node_path": node_path,
		"property_name": property_name,
		"property_value": serialized_value,
		"message": "Property %s retrieved for node %s" % [property_name, node_path]
	}

	return _create_success_response(request_id, data)

func _set_node_property(params: Dictionary, request_id: String) -> Dictionary:
	"""Set a property value on a node"""
	var node_path = params.get("node_path", "")
	var property_name = params.get("property_name", "")
	var property_value = params.get("property_value")

	if node_path == "":
		return _create_error_response(request_id, "Missing 'node_path' parameter")
	if property_name == "":
		return _create_error_response(request_id, "Missing 'property_name' parameter")

	var edited_scene = editor_interface.get_edited_scene_root()
	if not edited_scene:
		return _create_error_response(request_id, "No scene is currently being edited")

	var node = edited_scene.get_node_or_null(node_path)
	if not node:
		return _create_error_response(request_id, "Node not found: %s" % node_path)

	if not property_name in node:
		return _create_error_response(request_id, "Property '%s' not found in node" % property_name)

	# Attempt to deserialize and set the value
	var deserialized_value = _deserialize_value(property_value, node.get(property_name))
	node.set(property_name, deserialized_value)

	editor_interface.mark_scene_as_unsaved()

	var data = {
		"command": "SetNodeProperty",
		"node_path": node_path,
		"property_name": property_name,
		"property_value": property_value,
		"message": "Property %s set successfully for node %s" % [property_name, node_path]
	}

	return _create_success_response(request_id, data)

func _find_all_files_by_type(params: Dictionary, request_id: String) -> Dictionary:
	"""Find all files of a specific type in the project"""
	var file_type = params.get("file_type", "")
	var search_path = params.get("search_path", "res://")

	if file_type == "":
		return _create_error_response(request_id, "Missing 'file_type' parameter")

	var files = []
	_scan_directory(search_path, file_type, files)

	var data = {
		"command": "FindAllFilesByType",
		"file_type": file_type,
		"search_path": search_path,
		"files": files,
		"message": "Files of type %s found in %s" % [file_type, search_path]
	}

	return _create_success_response(request_id, data)

func _scan_directory(path: String, extension: String, files: Array) -> void:
	"""Recursively scan directory for files with specific extension"""
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		var full_path = path.path_join(file_name)

		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan_directory(full_path, extension, files)
		else:
			if file_name.ends_with("." + extension):
				files.append(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

func _run_tool_method(params: Dictionary, request_id: String) -> Dictionary:
	"""Execute a tool method (custom functionality)"""
	var method_name = params.get("method_name", "")
	var method_params = params.get("method_params", {})

	if method_name == "":
		return _create_error_response(request_id, "Missing 'method_name' parameter")

	var result = null

	# Implement custom tool methods here
	match method_name:
		"build_project":
			result = _tool_build_project()
		"reload_current_scene":
			result = _tool_reload_current_scene()
		"save_all_scenes":
			result = _tool_save_all_scenes()
		_:
			return _create_error_response(request_id, "Unknown tool method: %s" % method_name)

	var data = {
		"command": "RunToolMethod",
		"method_name": method_name,
		"result": result,
		"message": "Tool method %s executed successfully" % method_name
	}

	return _create_success_response(request_id, data)

## ========== Tool Methods ==========

func _tool_build_project() -> Dictionary:
	"""Build/export the project"""
	# Note: Actual building requires EditorExportPlugin
	return {
		"success": true,
		"message": "Build initiated (requires export configuration)"
	}

func _tool_reload_current_scene() -> Dictionary:
	"""Reload the currently edited scene"""
	if editor_interface:
		editor_interface.reload_scene_from_path(editor_interface.get_edited_scene_root().scene_file_path)
		return {"success": true, "message": "Scene reloaded"}
	return {"success": false, "message": "No editor interface"}

func _tool_save_all_scenes() -> Dictionary:
	"""Save all open scenes"""
	if editor_interface:
		editor_interface.save_all_scenes()
		return {"success": true, "message": "All scenes saved"}
	return {"success": false, "message": "No editor interface"}

## ========== Serialization Helpers ==========

func _serialize_value(value):
	"""Convert Godot value to JSON-serializable format"""
	match typeof(value):
		TYPE_VECTOR2:
			return {"x": value.x, "y": value.y}
		TYPE_VECTOR3:
			return {"x": value.x, "y": value.y, "z": value.z}
		TYPE_COLOR:
			return {"r": value.r, "g": value.g, "b": value.b, "a": value.a}
		TYPE_RECT2:
			return {"x": value.position.x, "y": value.position.y, "w": value.size.x, "h": value.size.y}
		TYPE_TRANSFORM2D, TYPE_TRANSFORM3D, TYPE_BASIS, TYPE_QUATERNION:
			return str(value)
		_:
			return value

func _deserialize_value(value, type_reference):
	"""Convert JSON value back to Godot type"""
	if typeof(type_reference) == TYPE_VECTOR2 and typeof(value) == TYPE_DICTIONARY:
		return Vector2(value.get("x", 0), value.get("y", 0))
	elif typeof(type_reference) == TYPE_VECTOR3 and typeof(value) == TYPE_DICTIONARY:
		return Vector3(value.get("x", 0), value.get("y", 0), value.get("z", 0))
	elif typeof(type_reference) == TYPE_COLOR and typeof(value) == TYPE_DICTIONARY:
		return Color(value.get("r", 0), value.get("g", 0), value.get("b", 0), value.get("a", 1))
	else:
		return value
