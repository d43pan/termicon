#!/usr/bin/env bash
# install.sh - install termicon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
CONFIG_DIR="$HOME/.config/termicon"

echo "Installing termicon..."

# Create config directory
mkdir -p "$CONFIG_DIR"
echo "  Config directory: $CONFIG_DIR"

# Install CLI to PATH
mkdir -p "$BIN_DIR"
ln -sf "$SCRIPT_DIR/termicon" "$BIN_DIR/termicon"
chmod +x "$SCRIPT_DIR/termicon"
echo "  CLI linked: $BIN_DIR/termicon"

# Ensure the shell plugin is executable
chmod +x "$SCRIPT_DIR/termicon.sh"

echo ""
echo "Done! Add the following line to your ~/.bashrc or ~/.zshrc:"
echo ""
echo "  source $SCRIPT_DIR/termicon.sh"
echo ""
echo "Then reload your shell or run:  source ~/.bashrc  (or ~/.zshrc)"
echo ""
echo "Quick start:"
echo "  termicon add ssh myserver.example.com 🖥️"
echo "  termicon add dir ~/work 💼"
echo "  termicon pick ssh myserver.example.com   # interactive picker"
echo "  termicon list"
