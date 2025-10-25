# Contributing to Godot MCP

Thank you for your interest in contributing to Godot MCP!

## Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Gucixdev/godotMCP.git
cd godotMCP
```

### 2. Set Up Virtual Environment

**Always use a virtual environment** to isolate dependencies:

```bash
# Automatic setup (recommended)
bash setup.sh

# Or manual setup
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# or
venv\Scripts\activate     # Windows

pip install -r requirements.txt
```

### 3. Activate Virtual Environment

**Before any Python work**, activate the virtual environment:

```bash
# Linux/macOS
source venv/bin/activate

# Windows
venv\Scripts\activate

# You should see (venv) in your prompt
```

### 4. Run Tests

```bash
# Verify setup
python verify_setup.py

# Run automated tests
bash run_tests.sh

# Test with Godot
python godot_mcp_server.py &
godot project.godot
```

## Project Structure

```
godotMCP/
├── Python Server
│   ├── godot_mcp_server.py     # Main WebSocket server
│   ├── test_client.py          # Test client
│   └── verify_setup.py         # Setup verification
│
├── Godot Plugin
│   └── addons/godot_mcp/
│       ├── plugin.gd           # EditorPlugin entry point
│       ├── mcp_client.gd       # WebSocket client
│       └── mcp_executor.gd     # Command executor
│
├── Scripts
│   ├── setup.sh                # Setup with venv
│   └── run_tests.sh            # Automated tests
│
└── Documentation
    ├── README.md               # Overview
    ├── INSTALLATION.md         # Setup guide
    ├── TESTING.md              # Testing guide
    └── CONTRIBUTING.md         # This file
```

## Making Changes

### Python Code

1. **Always use virtual environment**
   ```bash
   source venv/bin/activate
   ```

2. **Follow PEP 8 style**
   ```bash
   # Install dev dependencies
   pip install black flake8 mypy

   # Format code
   black godot_mcp_server.py

   # Check style
   flake8 godot_mcp_server.py
   ```

3. **Add type hints**
   ```python
   def my_function(param: str) -> Dict[str, Any]:
       pass
   ```

4. **Update tests**
   - Add tests for new commands
   - Update `test_client.py` if needed
   - Run `bash run_tests.sh`

### GDScript Code

1. **Follow Godot style guide**
   - Use tabs for indentation
   - Type hints where possible
   - Document public functions

2. **Test in Godot editor**
   ```bash
   godot project.godot
   ```

3. **Check Output panel** for errors/warnings

### Documentation

1. **Update relevant docs**
   - README.md - for user-facing changes
   - INSTALLATION.md - for setup changes
   - TESTING.md - for new tests
   - Code comments - for implementation details

2. **Use clear examples**
   ```markdown
   ### Example: Adding a Node

   \`\`\`python
   # Code example here
   \`\`\`
   ```

## Adding New MCP Commands

### 1. Update Python Server

Edit `godot_mcp_server.py`:

```python
# Add handler to command_handlers dict
self.command_handlers = {
    # ...
    'MyNewCommand': self.handle_my_new_command,
}

# Implement handler
async def handle_my_new_command(self, params: Dict[str, Any], request_id: str) -> Dict[str, Any]:
    logger.info(f"[MyNewCommand] Parameters: {params}")
    return self.create_success_response(request_id, {
        'command': 'MyNewCommand',
        'message': 'Success'
    })
```

### 2. Update Godot Executor

Edit `addons/godot_mcp/mcp_executor.gd`:

```gdscript
# Add to execute_command match statement
match command:
    # ...
    "MyNewCommand":
        response = _my_new_command(params, request_id)

# Implement command
func _my_new_command(params: Dictionary, request_id: String) -> Dictionary:
    """Do something with Godot API"""
    # Implementation here

    var data = {
        "command": "MyNewCommand",
        "result": "something",
        "message": "Success"
    }
    return _create_success_response(request_id, data)
```

### 3. Add Tests

Edit `test_client.py`:

```python
# Add test case
await send_command(
    websocket,
    'MyNewCommand',
    {'param1': 'value1'},
    'test-011'
)
```

### 4. Update Documentation

- Add command to README.md command table
- Add usage example
- Update TESTING.md test coverage

## Testing Your Changes

### Before Committing

```bash
# 1. Verify setup still works
python verify_setup.py

# 2. Run all tests
bash run_tests.sh

# 3. Test with Godot
python godot_mcp_server.py &
godot project.godot
python test_client.py

# 4. Check logs for errors
cat godot_mcp_server.log
```

### Test Checklist

- [ ] Virtual environment activates correctly
- [ ] Server starts without errors
- [ ] All existing commands still work
- [ ] New commands work as expected
- [ ] Godot plugin loads without errors
- [ ] No errors in Godot Output panel
- [ ] Documentation updated
- [ ] Code follows style guidelines

## Committing Changes

### Commit Message Format

```
<type>: <short description>

<detailed description>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance

**Example:**
```
feat: Add GetNodeChildren command

Implement new MCP command to get all children of a node.

- Add handler in Python server
- Implement in GDScript executor
- Add test case
- Update documentation

Closes #42
```

### Pull Request Process

1. **Create feature branch**
   ```bash
   git checkout -b feat/my-new-feature
   ```

2. **Make changes and commit**
   ```bash
   git add .
   git commit -m "feat: Add my new feature"
   ```

3. **Push and create PR**
   ```bash
   git push origin feat/my-new-feature
   gh pr create --title "Add my new feature" --base main
   ```

4. **PR Checklist**
   - [ ] Tests pass
   - [ ] Documentation updated
   - [ ] Code reviewed
   - [ ] No breaking changes (or documented)

## Dependency Management

### Adding Dependencies

If you need a new Python package:

1. **Activate venv**
   ```bash
   source venv/bin/activate
   ```

2. **Install package**
   ```bash
   pip install package-name
   ```

3. **Update requirements.txt**
   ```bash
   pip freeze > requirements.txt
   ```

4. **Commit both changes**
   ```bash
   git add requirements.txt
   git commit -m "chore: Add package-name dependency"
   ```

### Upgrading Dependencies

```bash
source venv/bin/activate
pip install --upgrade websockets
pip freeze > requirements.txt
```

## Virtual Environment Best Practices

### Do's ✅

- **Always activate before work**
  ```bash
  source venv/bin/activate
  ```

- **Check you're in venv**
  ```bash
  which python  # Should show ./venv/bin/python
  ```

- **Deactivate when done**
  ```bash
  deactivate
  ```

- **Recreate if corrupted**
  ```bash
  rm -rf venv
  bash setup.sh
  ```

### Don'ts ❌

- **Don't commit venv/** (already in .gitignore)
- **Don't install globally** unless necessary
- **Don't skip venv** "just this once"
- **Don't modify requirements.txt manually** (use pip freeze)

## Getting Help

- **Issue Tracker**: https://github.com/Gucixdev/godotMCP/issues
- **Discussions**: https://github.com/Gucixdev/godotMCP/discussions
- **Documentation**: See README.md, INSTALLATION.md, TESTING.md

## Code of Conduct

Be respectful, constructive, and collaborative. We're all here to make great tools!

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to Godot MCP! 🎉
