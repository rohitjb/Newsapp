#!/bin/sh
# scripts/install-hooks.sh
# Run this once after cloning: sh scripts/install-hooks.sh

HOOKS_DIR=".git/hooks"
SCRIPT_DIR="scripts"

cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Git hooks installed. Pre-commit SwiftLint check is now active."
