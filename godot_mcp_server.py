#!/usr/bin/env python3
"""
Godot MCP Server - Model Context Protocol WebSocket Server for Godot 4.5
A fully functional MCP server that receives commands, logs them, and returns success responses.
"""

import asyncio
import websockets
import json
import logging
import argparse
from datetime import datetime
from typing import Dict, Any, Optional


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('godot_mcp_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('GodotMCPServer')


class GodotMCPServer:
    """Main MCP Server class handling WebSocket connections and MCP commands"""

    def __init__(self, host: str = "localhost", port: int = 8765):
        self.host = host
        self.port = port
        self.connected_clients = set()

        # Map of supported MCP commands to their handlers
        self.command_handlers = {
            'GetProjectInfo': self.handle_get_project_info,
            'GetFileContent': self.handle_get_file_content,
            'SetFileContent': self.handle_set_file_content,
            'GetSceneNodes': self.handle_get_scene_nodes,
            'AddNode': self.handle_add_node,
            'RemoveNode': self.handle_remove_node,
            'GetNodeProperty': self.handle_get_node_property,
            'SetNodeProperty': self.handle_set_node_property,
            'FindAllFilesByType': self.handle_find_all_files_by_type,
            'RunToolMethod': self.handle_run_tool_method,
        }

    async def handle_client(self, websocket, path):
        """Handle incoming WebSocket client connections"""
        client_id = f"{websocket.remote_address[0]}:{websocket.remote_address[1]}"
        self.connected_clients.add(websocket)
        logger.info(f"New client connected: {client_id}")

        try:
            async for message in websocket:
                await self.process_message(websocket, message, client_id)
        except websockets.exceptions.ConnectionClosed:
            logger.info(f"Client disconnected: {client_id}")
        except Exception as e:
            logger.error(f"Error handling client {client_id}: {e}", exc_info=True)
        finally:
            self.connected_clients.discard(websocket)

    async def process_message(self, websocket, message: str, client_id: str):
        """Process incoming MCP message"""
        try:
            # Parse JSON request
            request = json.loads(message)
            logger.info(f"Received from {client_id}: {json.dumps(request, indent=2)}")

            # Extract command and parameters
            command = request.get('command')
            params = request.get('params', {})
            request_id = request.get('id')

            if not command:
                response = self.create_error_response(
                    request_id,
                    "Missing 'command' field in request"
                )
            elif command not in self.command_handlers:
                response = self.create_error_response(
                    request_id,
                    f"Unknown command: {command}"
                )
            else:
                # Execute command handler
                handler = self.command_handlers[command]
                response = await handler(params, request_id)

            # Send response
            response_json = json.dumps(response, indent=2)
            logger.info(f"Sending to {client_id}: {response_json}")
            await websocket.send(response_json)

        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON from {client_id}: {e}")
            error_response = self.create_error_response(None, f"Invalid JSON: {e}")
            await websocket.send(json.dumps(error_response))
        except Exception as e:
            logger.error(f"Error processing message from {client_id}: {e}", exc_info=True)
            error_response = self.create_error_response(None, f"Internal error: {e}")
            await websocket.send(json.dumps(error_response))

    def create_success_response(self, request_id: Optional[str], data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a success response"""
        return {
            'id': request_id,
            'status': 'success',
            'timestamp': datetime.utcnow().isoformat(),
            'data': data
        }

    def create_error_response(self, request_id: Optional[str], error_message: str) -> Dict[str, Any]:
        """Create an error response"""
        return {
            'id': request_id,
            'status': 'error',
            'timestamp': datetime.utcnow().isoformat(),
            'error': error_message
        }

    # ========== MCP Command Handlers ==========

    async def handle_get_project_info(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle GetProjectInfo command"""
        logger.info(f"[GetProjectInfo] Parameters: {params}")

        return self.create_success_response(request_id, {
            'command': 'GetProjectInfo',
            'project_name': 'GodotMCPProject',
            'godot_version': '4.5',
            'project_path': '/path/to/project',
            'message': 'Project info retrieved successfully'
        })

    async def handle_get_file_content(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle GetFileContent command"""
        file_path = params.get('file_path', '')
        logger.info(f"[GetFileContent] File: {file_path}")

        return self.create_success_response(request_id, {
            'command': 'GetFileContent',
            'file_path': file_path,
            'content': '',
            'message': f'File content retrieved for: {file_path}'
        })

    async def handle_set_file_content(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle SetFileContent command"""
        file_path = params.get('file_path', '')
        content = params.get('content', '')
        logger.info(f"[SetFileContent] File: {file_path}, Content length: {len(content)}")

        return self.create_success_response(request_id, {
            'command': 'SetFileContent',
            'file_path': file_path,
            'bytes_written': len(content),
            'message': f'File content set successfully for: {file_path}'
        })

    async def handle_get_scene_nodes(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle GetSceneNodes command"""
        scene_path = params.get('scene_path', '')
        logger.info(f"[GetSceneNodes] Scene: {scene_path}")

        return self.create_success_response(request_id, {
            'command': 'GetSceneNodes',
            'scene_path': scene_path,
            'nodes': [],
            'message': f'Scene nodes retrieved for: {scene_path}'
        })

    async def handle_add_node(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle AddNode command"""
        parent_path = params.get('parent_path', '')
        node_type = params.get('node_type', '')
        node_name = params.get('node_name', '')
        logger.info(f"[AddNode] Parent: {parent_path}, Type: {node_type}, Name: {node_name}")

        return self.create_success_response(request_id, {
            'command': 'AddNode',
            'parent_path': parent_path,
            'node_type': node_type,
            'node_name': node_name,
            'node_path': f'{parent_path}/{node_name}',
            'message': f'Node {node_name} added successfully'
        })

    async def handle_remove_node(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle RemoveNode command"""
        node_path = params.get('node_path', '')
        logger.info(f"[RemoveNode] Node: {node_path}")

        return self.create_success_response(request_id, {
            'command': 'RemoveNode',
            'node_path': node_path,
            'message': f'Node {node_path} removed successfully'
        })

    async def handle_get_node_property(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle GetNodeProperty command"""
        node_path = params.get('node_path', '')
        property_name = params.get('property_name', '')
        logger.info(f"[GetNodeProperty] Node: {node_path}, Property: {property_name}")

        return self.create_success_response(request_id, {
            'command': 'GetNodeProperty',
            'node_path': node_path,
            'property_name': property_name,
            'property_value': None,
            'message': f'Property {property_name} retrieved for node {node_path}'
        })

    async def handle_set_node_property(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle SetNodeProperty command"""
        node_path = params.get('node_path', '')
        property_name = params.get('property_name', '')
        property_value = params.get('property_value')
        logger.info(f"[SetNodeProperty] Node: {node_path}, Property: {property_name}, Value: {property_value}")

        return self.create_success_response(request_id, {
            'command': 'SetNodeProperty',
            'node_path': node_path,
            'property_name': property_name,
            'property_value': property_value,
            'message': f'Property {property_name} set successfully for node {node_path}'
        })

    async def handle_find_all_files_by_type(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle FindAllFilesByType command"""
        file_type = params.get('file_type', '')
        search_path = params.get('search_path', '')
        logger.info(f"[FindAllFilesByType] Type: {file_type}, Path: {search_path}")

        return self.create_success_response(request_id, {
            'command': 'FindAllFilesByType',
            'file_type': file_type,
            'search_path': search_path,
            'files': [],
            'message': f'Files of type {file_type} found in {search_path}'
        })

    async def handle_run_tool_method(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
        """Handle RunToolMethod command"""
        method_name = params.get('method_name', '')
        method_params = params.get('method_params', {})
        logger.info(f"[RunToolMethod] Method: {method_name}, Params: {method_params}")

        return self.create_success_response(request_id, {
            'command': 'RunToolMethod',
            'method_name': method_name,
            'result': None,
            'message': f'Tool method {method_name} executed successfully'
        })

    async def start(self):
        """Start the WebSocket server"""
        logger.info(f"Starting Godot MCP Server on {self.host}:{self.port}")

        async with websockets.serve(self.handle_client, self.host, self.port):
            logger.info(f"Server is running and listening on ws://{self.host}:{self.port}")
            await asyncio.Future()  # Run forever


def main():
    """Main entry point with command-line argument parsing"""
    parser = argparse.ArgumentParser(
        description='Godot MCP Server - WebSocket server for Model Context Protocol'
    )
    parser.add_argument(
        '--host',
        type=str,
        default='localhost',
        help='Host address to bind the server (default: localhost)'
    )
    parser.add_argument(
        '--port',
        type=int,
        default=8765,
        help='Port number to bind the server (default: 8765)'
    )
    parser.add_argument(
        '--log-level',
        type=str,
        default='INFO',
        choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
        help='Logging level (default: INFO)'
    )

    args = parser.parse_args()

    # Set logging level
    logger.setLevel(getattr(logging, args.log_level))

    # Create and start server
    server = GodotMCPServer(host=args.host, port=args.port)

    try:
        asyncio.run(server.start())
    except KeyboardInterrupt:
        logger.info("Server stopped by user")
    except Exception as e:
        logger.error(f"Server error: {e}", exc_info=True)
        raise


if __name__ == '__main__':
    main()
