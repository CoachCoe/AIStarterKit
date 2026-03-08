#!/usr/bin/env bash
#
# Initialize a new Polkadot project from templates
#
# Usage:
#   ./scripts/init.sh my-app              # Create Triangle host app
#   ./scripts/init.sh my-app --contracts  # Create smart contracts project
#
# Or run directly from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/example/AIStarterKit/main/scripts/init.sh | bash -s my-app
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script location (works when run locally or via curl)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Defaults
PROJECT_NAME=""
PROJECT_TYPE="host-app"
TEMPLATE_DIR=""

usage() {
  cat <<EOF
Usage: $(basename "$0") <project-name> [options]

Create a new Polkadot project from templates.

Options:
  --host-app      Create a Triangle host app (default)
  --contracts     Create a smart contracts project (Foundry)
  -h, --help      Show this help message

Examples:
  $(basename "$0") my-app              # Triangle host app
  $(basename "$0") my-app --contracts  # Smart contracts
EOF
  exit 0
}

error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

info() {
  echo -e "${BLUE}→${NC} $1"
}

success() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}!${NC} $1"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      usage
      ;;
    --host-app)
      PROJECT_TYPE="host-app"
      shift
      ;;
    --contracts)
      PROJECT_TYPE="contracts"
      shift
      ;;
    -*)
      error "Unknown option: $1"
      ;;
    *)
      if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="$1"
      else
        error "Unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

# Validate project name
if [[ -z "$PROJECT_NAME" ]]; then
  error "Project name required. Usage: $(basename "$0") <project-name>"
fi

if [[ "$PROJECT_NAME" =~ [^a-zA-Z0-9_-] ]]; then
  error "Project name can only contain letters, numbers, hyphens, and underscores"
fi

if [[ -e "$PROJECT_NAME" ]]; then
  error "Directory '$PROJECT_NAME' already exists"
fi

# Set template directory based on type
case $PROJECT_TYPE in
  host-app)
    TEMPLATE_DIR="$REPO_ROOT/templates/minimal-host-app"
    if [[ ! -d "$TEMPLATE_DIR" ]]; then
      error "Template not found: $TEMPLATE_DIR"
    fi
    ;;
  contracts)
    # For contracts, we'll create a Foundry project
    TEMPLATE_DIR=""
    ;;
esac

echo ""
echo -e "${GREEN}Creating Polkadot project: $PROJECT_NAME${NC}"
echo ""

# Create project based on type
if [[ "$PROJECT_TYPE" == "host-app" ]]; then
  info "Copying template..."
  cp -r "$TEMPLATE_DIR" "$PROJECT_NAME"

  info "Updating package.json..."
  cd "$PROJECT_NAME"

  # Update package name using sed (works on both macOS and Linux)
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "s/\"name\": \"minimal-host-app\"/\"name\": \"$PROJECT_NAME\"/" package.json
  else
    sed -i "s/\"name\": \"minimal-host-app\"/\"name\": \"$PROJECT_NAME\"/" package.json
  fi

  # Install dependencies
  info "Installing dependencies..."
  if command -v pnpm &> /dev/null; then
    pnpm install --silent
  elif command -v npm &> /dev/null; then
    npm install --silent
  else
    warn "No package manager found. Run 'npm install' manually."
  fi

  success "Project created!"
  echo ""
  echo -e "${GREEN}Next steps:${NC}"
  echo ""
  echo "  cd $PROJECT_NAME"
  echo "  npm run dev        # Start dev server at localhost:8000"
  echo "  npm run build      # Build for deployment"
  echo "  ./deploy.sh $PROJECT_NAME  # Deploy to $PROJECT_NAME.dot.li"
  echo ""
  echo -e "${BLUE}Open in browser:${NC} http://localhost:8000"
  echo ""
  echo -e "${YELLOW}Note:${NC} The app runs inside Triangle hosts (Polkadot Desktop, etc.)"
  echo "      For local testing, open in browser to see console output."
  echo ""

elif [[ "$PROJECT_TYPE" == "contracts" ]]; then
  # Check for Foundry
  if ! command -v forge &> /dev/null; then
    error "Foundry not installed. Install with: curl -L https://foundry.paradigm.xyz | bash && foundryup"
  fi

  info "Creating Foundry project..."
  forge init "$PROJECT_NAME"
  cd "$PROJECT_NAME"

  info "Installing OpenZeppelin contracts..."
  forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-git
  forge install OpenZeppelin/openzeppelin-contracts --no-git

  info "Configuring for Polkadot Asset Hub..."

  # Add remappings
  cat > remappings.txt <<EOF
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/
EOF

  # Update foundry.toml for Asset Hub
  cat > foundry.toml <<EOF
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.28"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
paseo = "https://paseo-asset-hub-eth-rpc.polkadot.io"
mainnet = "https://polkadot-asset-hub-eth-rpc.polkadot.io"
previewnet = "https://previewnet.substrate.dev/eth-rpc"
local = "http://127.0.0.1:8545"

[etherscan]
paseo = { key = "", chain = 420420421, url = "https://paseo.subscan.io/api" }
mainnet = { key = "", chain = 420420420, url = "https://assethub-polkadot.subscan.io/api" }
EOF

  # Create example UUPS contract
  cat > src/Counter.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/// @title Counter
/// @notice Simple upgradeable counter for demonstration
contract Counter is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public count;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    function increment() external {
        count += 1;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
EOF

  # Create deploy script
  cat > script/Deploy.s.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy implementation
        Counter impl = new Counter();
        console.log("Implementation:", address(impl));

        // Deploy proxy
        bytes memory initData = abi.encodeCall(Counter.initialize, (deployer));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        console.log("Proxy:", address(proxy));

        vm.stopBroadcast();
    }
}
EOF

  # Create test file
  cat > test/Counter.t.sol <<'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract CounterTest is Test {
    Counter public counter;
    address public owner;

    function setUp() public {
        owner = address(this);

        // Deploy implementation
        Counter impl = new Counter();

        // Deploy proxy
        bytes memory initData = abi.encodeCall(Counter.initialize, (owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        counter = Counter(address(proxy));
    }

    function test_InitialCount() public view {
        assertEq(counter.count(), 0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.count(), 1);
    }

    function test_MultipleIncrements() public {
        counter.increment();
        counter.increment();
        counter.increment();
        assertEq(counter.count(), 3);
    }

    function testFuzz_Increment(uint8 times) public {
        for (uint8 i = 0; i < times; i++) {
            counter.increment();
        }
        assertEq(counter.count(), times);
    }
}
EOF

  # Create .env.example
  cat > .env.example <<'EOF'
# Get from p1p or create new wallet
PRIVATE_KEY=0x...

# Optional: For contract verification
ETHERSCAN_API_KEY=
EOF

  # Create .gitignore additions
  cat >> .gitignore <<'EOF'

# Environment
.env
.env.local

# Deployment artifacts
broadcast/
EOF

  success "Project created!"
  echo ""
  echo -e "${GREEN}Next steps:${NC}"
  echo ""
  echo "  cd $PROJECT_NAME"
  echo "  cp .env.example .env     # Add your private key"
  echo "  forge build              # Compile contracts"
  echo "  forge test               # Run tests"
  echo ""
  echo -e "${BLUE}Deploy to Paseo:${NC}"
  echo "  source .env"
  echo "  forge script script/Deploy.s.sol --rpc-url paseo --broadcast"
  echo ""
fi
