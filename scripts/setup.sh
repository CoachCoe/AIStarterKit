#!/bin/bash
# setup.sh - Initialize a new project with AI Starter Kit configuration
#
# Usage: /path/to/AIStarterKit/scripts/setup.sh
#
# Run this script from within your target project directory.
# It will copy the .claude configuration and CLAUDE.md template.

set -e

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STARTER_KIT_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_DIR="$(pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🚀 AI Starter Kit Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Source:  $STARTER_KIT_DIR"
echo "Target:  $TARGET_DIR"
echo ""

# Check if .claude already exists
if [ -d "$TARGET_DIR/.claude" ]; then
  echo "${YELLOW}⚠️  .claude directory already exists in target.${NC}"
  read -p "Overwrite? (y/N) " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
  fi
fi

# Copy .claude directory
echo "📁 Copying .claude directory..."
cp -r "$STARTER_KIT_DIR/.claude" "$TARGET_DIR/"

# Copy CLAUDE.md if it doesn't exist
if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo "📄 Copying CLAUDE.md template..."
  cp "$STARTER_KIT_DIR/CLAUDE.md" "$TARGET_DIR/"
else
  echo "${YELLOW}ℹ️  CLAUDE.md already exists, skipping (review template at $STARTER_KIT_DIR/CLAUDE.md)${NC}"
fi

# Copy scripts directory
echo "📜 Copying scripts..."
mkdir -p "$TARGET_DIR/scripts"
cp "$STARTER_KIT_DIR/scripts/skill-sync.sh" "$TARGET_DIR/scripts/"
chmod +x "$TARGET_DIR/scripts/skill-sync.sh"

echo ""
echo "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Next steps:"
echo ""
echo "1. Edit CLAUDE.md with your project details:"
echo "   - Project name and description"
echo "   - Architecture and directory structure"
echo "   - Technology stack"
echo "   - Coding standards"
echo ""
echo "2. Edit .claude/AGENTS.md:"
echo "   - Update skills routing table"
echo "   - Add project-specific invariants"
echo "   - Define domain terminology"
echo ""
echo "3. Add domain-specific skills to .claude/skills/"
echo ""
echo "4. Configure reference repos in scripts/skill-sync.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
