#!/bin/bash
# skill-sync.sh - Check reference repositories for skill updates
#
# Usage: ./scripts/skill-sync.sh
#
# Configure REFERENCE_REPOS below with paths to your reference repositories.
# The script will:
#   1. Check if each repo has updates available
#   2. Show recent commits if updates exist
#   3. Optionally pull updates

set -e

# Configure your reference repositories here
REFERENCE_REPOS=(
  # Example paths - customize for your setup:
  # "/Users/yourname/Documents/dev/product-infrastructure"
  # "/Users/yourname/Documents/dev/identity-backend"
  # "/Users/yourname/Documents/dev/erc8004"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔄 Checking reference repositories for updates..."
echo ""

if [ ${#REFERENCE_REPOS[@]} -eq 0 ]; then
  echo "${YELLOW}⚠️  No reference repositories configured.${NC}"
  echo ""
  echo "Edit scripts/skill-sync.sh and add paths to REFERENCE_REPOS array:"
  echo ""
  echo "  REFERENCE_REPOS=("
  echo '    "/path/to/reference-repo-1"'
  echo '    "/path/to/reference-repo-2"'
  echo "  )"
  echo ""
  exit 0
fi

UPDATES_FOUND=0

for repo in "${REFERENCE_REPOS[@]}"; do
  if [ ! -d "$repo" ]; then
    echo "${RED}✗ $repo does not exist${NC}"
    continue
  fi

  repo_name=$(basename "$repo")
  cd "$repo"

  # Fetch without output
  git fetch origin -q 2>/dev/null

  # Get current and remote HEAD
  LOCAL=$(git rev-parse HEAD 2>/dev/null)
  REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "${YELLOW}⚠️  $repo_name has updates available${NC}"
    echo "   Recent commits:"
    git log --oneline HEAD..origin/main 2>/dev/null | head -5 || \
    git log --oneline HEAD..origin/master 2>/dev/null | head -5
    echo ""

    # Check for skill changes specifically
    SKILL_CHANGES=$(git diff --name-only HEAD..origin/main -- '.claude/skills/' 2>/dev/null || \
                   git diff --name-only HEAD..origin/master -- '.claude/skills/' 2>/dev/null)

    if [ -n "$SKILL_CHANGES" ]; then
      echo "   ${YELLOW}Skill files changed:${NC}"
      echo "$SKILL_CHANGES" | sed 's/^/   - /'
      echo ""
    fi

    UPDATES_FOUND=1
  else
    echo "${GREEN}✓ $repo_name is up to date${NC}"
  fi

  cd - > /dev/null
done

echo ""

if [ $UPDATES_FOUND -eq 1 ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "${YELLOW}Updates available! To pull updates:${NC}"
  echo ""
  echo "  cd /path/to/repo && git pull"
  echo ""
  echo "Then review .claude/skills/ for changes to incorporate."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
  echo "${GREEN}All reference repositories are up to date.${NC}"
fi
