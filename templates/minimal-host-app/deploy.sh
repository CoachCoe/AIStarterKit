#!/usr/bin/env bash
#
# deploy.sh — Deploy a static SPA to Polkadot Bulletin via DotNS
#
# Usage:
#   ./deploy.sh <name>
#
# Examples:
#   ./deploy.sh my-app           # deploys dist/ → my-app.dot
#   ./deploy.sh test.my-app      # deploys dist/ → test.my-app.dot (subdomain)
#
# Prerequisites:
#   - dotns CLI installed and linked (npm link)
#   - DOTNS_MNEMONIC env var set (BIP39 mnemonic)
#   - jq installed
#   - Account funded via https://faucet.polkadot.io/
#   - Account authorized via https://paritytech.github.io/polkadot-bulletin-chain/
#
set -euo pipefail

NAME="${1:?Usage: ./deploy.sh <name>}"
BUILD_DIR="./dist"

if [ -z "${DOTNS_MNEMONIC:-}" ]; then
  echo "Error: DOTNS_MNEMONIC env var is required."
  echo ""
  echo "Option 1 - Direct:"
  echo "  export DOTNS_MNEMONIC=\"your twelve word mnemonic ...\""
  echo ""
  echo "Option 2 - Via p1p (recommended):"
  echo "  export DOTNS_MNEMONIC=\$(p1p read \"p1p://<locker>/dotns/customFields.mnemonic\" -n)"
  exit 1
fi
AUTH=(--mnemonic "$DOTNS_MNEMONIC")

echo "==> Deploying ${BUILD_DIR} to ${NAME}.dot"

# 1. Authorize account for Bulletin TransactionStorage
echo ""
echo "--- Step 1: Authorize account for Bulletin ---"
ADDRESS=$(dotns account address "${AUTH[@]}")
echo "Account: $ADDRESS"

dotns bulletin authorize "$ADDRESS" "${AUTH[@]}" || {
  echo "(already authorized — continuing)"
}

# 2. Upload to Bulletin
echo ""
echo "--- Step 2: Upload to Bulletin ---"
RESULT=$(dotns bulletin upload "$BUILD_DIR" --json --parallel "${AUTH[@]}")
CID=$(echo "$RESULT" | jq -r '.cid')
echo "CID: $CID"

# 3. Register domain (and subdomain if needed)
echo ""
echo "--- Step 3: Register domain (if needed) ---"

if [[ "$NAME" == *.* ]]; then
  # Subdomain: e.g. "test.mytestapp" → parent="mytestapp", sub="test"
  SUB="${NAME%%.*}"
  PARENT="${NAME#*.}"

  # Ensure parent domain is registered
  LOOKUP=$(dotns lookup name "$PARENT" --json 2>&1 || true)
  EXISTS=$(echo "$LOOKUP" | jq -r '.exists' 2>/dev/null || echo "false")

  if [ "$EXISTS" != "true" ]; then
    echo "Registering parent ${PARENT}.dot ..."
    dotns register domain --name "$PARENT" --status full "${AUTH[@]}"
  else
    echo "${PARENT}.dot already registered — skipping"
  fi

  # Register subdomain
  echo "Registering subdomain ${SUB}.${PARENT}.dot ..."
  dotns register subname --name "$SUB" --parent "$PARENT" "${AUTH[@]}"
else
  # Base domain
  LOOKUP=$(dotns lookup name "$NAME" --json 2>&1 || true)
  EXISTS=$(echo "$LOOKUP" | jq -r '.exists' 2>/dev/null || echo "false")

  if [ "$EXISTS" != "true" ]; then
    echo "Registering ${NAME}.dot ..."
    dotns register domain --name "$NAME" --status full "${AUTH[@]}"
  else
    echo "${NAME}.dot already registered — skipping"
  fi
fi

# 4. Set contenthash
echo ""
echo "--- Step 4: Set contenthash ---"
dotns content set "$NAME" "$CID" "${AUTH[@]}"

echo ""
echo "==> Done! Your site is live at:"
echo "    https://${NAME}.dot.li"
