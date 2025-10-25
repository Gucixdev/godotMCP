#!/usr/bin/env python3
"""
Setup Verification Script for Godot MCP
Checks if everything is configured correctly
"""

import sys
import subprocess
import os

def check_python_version():
    """Check Python version"""
    print("🔍 Checking Python version...")
    version = sys.version_info
    if version.major >= 3 and version.minor >= 9:
        print(f"  ✅ Python {version.major}.{version.minor}.{version.micro} (OK)")
        return True
    else:
        print(f"  ❌ Python {version.major}.{version.minor}.{version.micro} (Need 3.9+)")
        return False

def check_dependencies():
    """Check if required Python packages are installed"""
    print("\n🔍 Checking Python dependencies...")

    try:
        import websockets
        print(f"  ✅ websockets {websockets.__version__} (installed)")
        return True
    except ImportError:
        print("  ❌ websockets (NOT installed)")
        print("     Install with: pip install -r requirements.txt")
        return False

def check_files():
    """Check if all required files exist"""
    print("\n🔍 Checking project files...")

    required_files = {
        "Python Server": [
            "godot_mcp_server.py",
            "test_client.py",
            "requirements.txt"
        ],
        "Godot Plugin": [
            "addons/godot_mcp/plugin.cfg",
            "addons/godot_mcp/plugin.gd",
            "addons/godot_mcp/mcp_client.gd",
            "addons/godot_mcp/mcp_executor.gd"
        ],
        "Configuration": [
            "project.godot",
            ".gitignore"
        ],
        "Documentation": [
            "README.md",
            "INSTALLATION.md"
        ]
    }

    all_ok = True
    for category, files in required_files.items():
        print(f"\n  {category}:")
        for file in files:
            if os.path.exists(file):
                size = os.path.getsize(file)
                print(f"    ✅ {file} ({size} bytes)")
            else:
                print(f"    ❌ {file} (MISSING)")
                all_ok = False

    return all_ok

def check_godot():
    """Check if Godot is available"""
    print("\n🔍 Checking Godot installation...")

    try:
        result = subprocess.run(
            ["godot", "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )

        if result.returncode == 0:
            version = result.stdout.strip()
            print(f"  ✅ Godot found: {version}")

            if "4.5" in version or "4.4" in version or "4.3" in version:
                print("     ℹ️  Compatible version detected")
                return True
            else:
                print("     ⚠️  Version might not be compatible (need 4.5)")
                return True
        else:
            print("  ⚠️  Godot found but version check failed")
            return True

    except FileNotFoundError:
        print("  ⚠️  Godot not found in PATH")
        print("     You can still use the Python server")
        return True
    except Exception as e:
        print(f"  ⚠️  Error checking Godot: {e}")
        return True

def check_port():
    """Check if port 8765 is available"""
    print("\n🔍 Checking port availability...")

    import socket

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(1)

    try:
        result = sock.connect_ex(('localhost', 8765))

        if result == 0:
            print("  ⚠️  Port 8765 is already in use")
            print("     Stop the existing server or use --port to specify another port")
            sock.close()
            return False
        else:
            print("  ✅ Port 8765 is available")
            sock.close()
            return True

    except Exception as e:
        print(f"  ⚠️  Error checking port: {e}")
        sock.close()
        return True

def print_summary(results):
    """Print summary and next steps"""
    print("\n" + "="*60)
    print("📋 VERIFICATION SUMMARY")
    print("="*60)

    all_passed = all(results.values())

    for check, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  {status} - {check}")

    print("="*60)

    if all_passed:
        print("\n🎉 All checks passed! You're ready to go!")
        print("\n📚 Quick Start:")
        print("  1. Start the server:")
        print("     python godot_mcp_server.py")
        print("\n  2. Open Godot:")
        print("     godot project.godot")
        print("\n  3. Test the connection:")
        print("     python test_client.py")
        print("\n  4. Read the docs:")
        print("     cat INSTALLATION.md")
    else:
        print("\n⚠️  Some checks failed. Please fix the issues above.")
        print("\n📚 For help, see:")
        print("  - INSTALLATION.md (detailed setup guide)")
        print("  - README.md (project overview)")

    print("")

def main():
    print("╔" + "="*58 + "╗")
    print("║" + " "*10 + "Godot MCP Setup Verification" + " "*20 + "║")
    print("╚" + "="*58 + "╝")
    print()

    results = {
        "Python Version": check_python_version(),
        "Dependencies": check_dependencies(),
        "Project Files": check_files(),
        "Godot Installation": check_godot(),
        "Port Availability": check_port()
    }

    print_summary(results)

    return 0 if all(results.values()) else 1

if __name__ == '__main__':
    sys.exit(main())
