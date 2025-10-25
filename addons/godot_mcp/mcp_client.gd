extends Node

## MCP WebSocket Client
## Connects to Python MCP server and receives/processes commands

var socket: WebSocketPeer = null
var executor: Node = null
var connected: bool = false
var server_url: String = ""

func _ready() -> void:
	set_process(true)

func connect_to_server(host: String, port: int) -> void:
	server_url = "ws://%s:%d" % [host, port]
	print("[MCP Client] Connecting to %s..." % server_url)

	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(server_url)

	if err != OK:
		push_error("[MCP Client] Failed to connect: %d" % err)
		return

	print("[MCP Client] Connection initiated")

func disconnect_from_server() -> void:
	if socket:
		socket.close()
		socket = null
		connected = false
		print("[MCP Client] Disconnected from server")

func _process(_delta: float) -> void:
	if not socket:
		return

	socket.poll()
	var state = socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				print("[MCP Client] Connected to %s" % server_url)

			# Receive and process messages
			while socket.get_available_packet_count():
				var packet = socket.get_packet()
				var message = packet.get_string_from_utf8()
				_handle_message(message)

		WebSocketPeer.STATE_CLOSING:
			pass

		WebSocketPeer.STATE_CLOSED:
			if connected:
				var code = socket.get_close_code()
				var reason = socket.get_close_reason()
				print("[MCP Client] Connection closed. Code: %d, Reason: %s" % [code, reason])
				connected = false

func _handle_message(message: String) -> void:
	print("[MCP Client] Received: %s" % message)

	var json = JSON.new()
	var parse_result = json.parse(message)

	if parse_result != OK:
		push_error("[MCP Client] Failed to parse JSON: %s" % message)
		_send_error_response(null, "Invalid JSON")
		return

	var request = json.data
	if typeof(request) != TYPE_DICTIONARY:
		push_error("[MCP Client] Request is not a dictionary")
		_send_error_response(null, "Request must be a dictionary")
		return

	var command = request.get("command", "")
	var params = request.get("params", {})
	var request_id = request.get("id", "")

	if command == "":
		_send_error_response(request_id, "Missing 'command' field")
		return

	# Execute command via executor
	if executor:
		executor.execute_command(command, params, request_id, self)
	else:
		_send_error_response(request_id, "Executor not initialized")

func send_response(response: Dictionary) -> void:
	if not socket or socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_error("[MCP Client] Cannot send response - not connected")
		return

	var json_string = JSON.stringify(response, "\t")
	print("[MCP Client] Sending: %s" % json_string)

	var err = socket.send_text(json_string)
	if err != OK:
		push_error("[MCP Client] Failed to send response: %d" % err)

func _send_error_response(request_id, error_message: String) -> void:
	var response = {
		"id": request_id,
		"status": "error",
		"timestamp": Time.get_datetime_string_from_system(),
		"error": error_message
	}
	send_response(response)
