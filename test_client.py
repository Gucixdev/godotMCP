#!/usr/bin/env python3
"""
Test client for Godot MCP Server
Demonstrates how to connect and send commands to the server
"""

import asyncio
import websockets
import json


async def send_command(websocket, command, params, request_id):
    """Send a command to the MCP server and print the response"""
    request = {
        'id': request_id,
        'command': command,
        'params': params
    }

    print(f"\n{'='*60}")
    print(f"Sending: {command}")
    print(f"Request ID: {request_id}")
    print(f"Parameters: {json.dumps(params, indent=2)}")
    print(f"{'='*60}")

    await websocket.send(json.dumps(request))

    response = await websocket.recv()
    response_data = json.loads(response)

    print(f"\nResponse:")
    print(json.dumps(response_data, indent=2))

    return response_data


async def test_all_commands():
    """Test all MCP commands"""
    uri = "ws://localhost:8765"

    print(f"Connecting to {uri}...")

    async with websockets.connect(uri) as websocket:
        print("Connected successfully!\n")

        # Test 1: GetProjectInfo
        await send_command(
            websocket,
            'GetProjectInfo',
            {},
            'test-001'
        )

        # Test 2: GetFileContent
        await send_command(
            websocket,
            'GetFileContent',
            {'file_path': 'res://scripts/player.gd'},
            'test-002'
        )

        # Test 3: SetFileContent
        await send_command(
            websocket,
            'SetFileContent',
            {
                'file_path': 'res://scripts/player.gd',
                'content': 'extends CharacterBody2D\n\nfunc _ready():\n\tpass\n'
            },
            'test-003'
        )

        # Test 4: GetSceneNodes
        await send_command(
            websocket,
            'GetSceneNodes',
            {'scene_path': 'res://scenes/main.tscn'},
            'test-004'
        )

        # Test 5: AddNode
        await send_command(
            websocket,
            'AddNode',
            {
                'parent_path': 'Root',
                'node_type': 'Sprite2D',
                'node_name': 'PlayerSprite'
            },
            'test-005'
        )

        # Test 6: RemoveNode
        await send_command(
            websocket,
            'RemoveNode',
            {'node_path': 'Root/PlayerSprite'},
            'test-006'
        )

        # Test 7: GetNodeProperty
        await send_command(
            websocket,
            'GetNodeProperty',
            {
                'node_path': 'Root/Player',
                'property_name': 'position'
            },
            'test-007'
        )

        # Test 8: SetNodeProperty
        await send_command(
            websocket,
            'SetNodeProperty',
            {
                'node_path': 'Root/Player',
                'property_name': 'position',
                'property_value': {'x': 100, 'y': 200}
            },
            'test-008'
        )

        # Test 9: FindAllFilesByType
        await send_command(
            websocket,
            'FindAllFilesByType',
            {
                'file_type': 'gd',
                'search_path': 'res://scripts'
            },
            'test-009'
        )

        # Test 10: RunToolMethod
        await send_command(
            websocket,
            'RunToolMethod',
            {
                'method_name': 'build_project',
                'method_params': {}
            },
            'test-010'
        )

        # Test error handling
        print(f"\n{'='*60}")
        print("Testing error handling - sending invalid command")
        print(f"{'='*60}")
        await send_command(
            websocket,
            'InvalidCommand',
            {},
            'test-error'
        )

        print("\n" + "="*60)
        print("All tests completed!")
        print("="*60)


if __name__ == '__main__':
    try:
        asyncio.run(test_all_commands())
    except ConnectionRefusedError:
        print("\nError: Could not connect to server.")
        print("Make sure the server is running with:")
        print("  python godot_mcp_server.py")
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
    except Exception as e:
        print(f"\nError: {e}")
