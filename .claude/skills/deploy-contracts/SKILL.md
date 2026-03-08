---
name: deploy-contracts
description: "Deploy smart contracts to Polkadot Asset Hub. Triggers: deploy, deployment, paseo, mainnet"
---

# Deploy Contracts

## When to Activate

- Deploying contracts to Paseo testnet or mainnet
- Setting up proxy deployments
- Upgrading existing contracts
- Configuring post-deployment (tokens, roles)

## Global Invariants

| Rule | Enforcement |
|------|-------------|
| Always use --slow flag | REQUIRED (prevents nonce issues) |
| Verify .env is sourced | REQUIRED before deployment |
| Log all deployed addresses | REQUIRED for verification |
| Use UUPS proxy for upgradeable contracts | REQUIRED |

## Network Configuration

| Network | RPC | Chain ID | Use Case |
|---------|-----|----------|----------|
| Polkadot Hub TestNet | https://eth-rpc-testnet.polkadot.io | 420420417 | Integration testing |
| Polkadot Mainnet | https://polkadot-asset-hub-eth-rpc.polkadot.io | TBD | Production |
| Local Hardhat/Anvil | http://127.0.0.1:8545 | 31337 | Unit tests |

**Note:** The TestNet is also called "Paseo Asset Hub" or "Polkadot Hub TestNet".

## Deployment Workflow

### 1. Pre-deployment Checklist

```bash
# Option A: Use p1p for secrets (recommended)
# Requires .env.p1p file with p1p:// URIs
p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol --rpc-url paseo --broadcast --slow

# Option B: Manual .env
source .env
echo "Admin: $ADMIN_ADDRESS"
echo "Private key set: $([ -n "$PRIVATE_KEY" ] && echo 'yes' || echo 'NO')"

# Build contracts
forge build

# Run tests
forge test -vvv
```

**p1p Setup (one-time):**
```bash
# Sign in to p1p
p1p signin --mnemonic

# Store deployment secrets
p1p locker create -n "my-deployment"
p1p item create -l "my-deployment" -t "contracts" \
  --category custom \
  --field private_key="0x..." \
  --field deployer_address="0x..."

# Create .env.p1p template (safe to commit)
cat > .env.p1p << 'EOF'
PRIVATE_KEY=p1p://my-deployment/contracts/customFields.private_key
DEPLOYER_ADDRESS=p1p://my-deployment/contracts/customFields.deployer_address
PASEO_RPC_URL=https://eth-rpc-testnet.polkadot.io
EOF
```

### 2. Deploy to Local Anvil (Unit Tests)

```bash
# Terminal 1: Start Anvil
anvil --chain-id 420420421

# Terminal 2: Deploy
forge script script/Deploy.s.sol --rpc-url local --broadcast
```

### 3. Deploy to Previewnet (Integration - No Tokens Needed)

```bash
# Pre-funded dev accounts - no .env needed
forge script script/Deploy.s.sol \
  --rpc-url previewnet \
  --broadcast \
  --slow \
  -vvvv
```

### 4. Deploy to Paseo (Pre-Production)

```bash
source .env
forge script script/Deploy.s.sol \
  --rpc-url paseo \
  --broadcast \
  --slow \
  -vvvv
```

## UUPS Proxy Deployment Pattern

```solidity
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

function run() public {
    vm.startBroadcast(deployerPrivateKey);

    // 1. Deploy implementation
    MyContract impl = new MyContract();

    // 2. Deploy proxy with initializer
    ERC1967Proxy proxy = new ERC1967Proxy(
        address(impl),
        abi.encodeCall(MyContract.initialize, (admin))
    );

    // 3. Cast to implementation type
    MyContract instance = MyContract(address(proxy));

    vm.stopBroadcast();

    console.log("Implementation:", address(impl));
    console.log("Proxy:", address(proxy));
}
```

## Post-Deployment Configuration

### Link Contracts (if needed)

```solidity
// Example: Set dependencies between contracts
contractA.setContractB(address(contractB));
contractB.setContractA(address(contractA));
```

### Add Supported Tokens

```bash
# Set environment
export CONTRACT_ADDRESS=0x...
export TOKEN_ADDRESS=0x...

# Run configuration script
forge script script/Configure.s.sol --rpc-url paseo --broadcast
```

## Upgrading Contracts

```solidity
// 1. Deploy new implementation
MyContractV2 newImpl = new MyContractV2();

// 2. Upgrade via proxy
MyContract(proxyAddress).upgradeToAndCall(
    address(newImpl),
    ""  // or encoded re-initialization call
);
```

## Hardhat Deployment (PolkaVM)

For projects using Hardhat with `@parity/hardhat-polkadot` for PolkaVM compilation:

### Hardhat Config for PolkaVM

```typescript
// hardhat.config.ts
networks: {
  paseo: {
    url: process.env.PASEO_RPC_URL || 'https://eth-rpc-testnet.polkadot.io',
    chainId: 420420417,
    accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    polkadot: {
      target: 'pvm',  // Required for PolkaVM
    },
  },
},
resolc: {
  compilerSource: 'binary',
  settings: {
    resolcPath: './bin/resolc',
  },
},
```

### Verify PolkaVM Compilation

Check that artifacts have PVM bytecode (starts with `0x50564d00`):
```bash
cat artifacts/contracts/MyContract.sol/MyContract.json | jq -r '.bytecode' | head -c 20
# Should output: 0x50564d0000...
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Transaction is temporarily banned | Use ethers directly with explicit gas params (see below) |
| Transaction underpriced | Set explicit `gasPrice: feeData.gasPrice * 2n` |
| Nonce too low | Use `--slow` flag or wait and retry |
| Out of gas | Increase gas limit: `gasLimit: 10_000_000n` |
| Signature invalid | Check PRIVATE_KEY format (with 0x prefix) |

### "Transaction is temporarily banned" Workaround

If deployment fails with this error, deploy using ethers directly:

```typescript
import { ethers } from 'ethers';
import fs from 'fs';

const provider = new ethers.JsonRpcProvider('https://eth-rpc-testnet.polkadot.io');
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const artifact = JSON.parse(fs.readFileSync('./artifacts/.../MyContract.json', 'utf8'));
const feeData = await provider.getFeeData();

const tx = await wallet.sendTransaction({
  data: artifact.bytecode,
  gasLimit: 10_000_000n,
  gasPrice: feeData.gasPrice ? feeData.gasPrice * 2n : 1000000000n,
});
const receipt = await tx.wait();
console.log('Contract deployed at:', receipt?.contractAddress);
```

## Foundry.toml Configuration

```toml
[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
solc = "0.8.24"
optimizer = true
optimizer_runs = 200
evm_version = "cancun"

[rpc_endpoints]
previewnet = "https://previewnet.substrate.dev/eth-rpc"
paseo = "${PASEO_RPC_URL}"
polkadot = "${POLKADOT_RPC_URL}"
local = "http://127.0.0.1:8545"
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Deploy without --slow | FORBIDDEN | Causes nonce issues |
| Skip .env verification | FORBIDDEN | Missing keys fail silently |
| Deploy upgradeable without proxy | FORBIDDEN | Breaks upgrade path |
| Initialize in constructor | FORBIDDEN | Use initializer modifier |
| Forget storage gaps | FORBIDDEN | Blocks future upgrades |

---

## Verification (REQUIRED before marking complete)

### Pre-Deployment

```bash
# All tests pass
forge test -vvv

# Contracts compile
forge build

# Environment configured
echo "PRIVATE_KEY: $([ -n "$PRIVATE_KEY" ] && echo 'set' || echo 'MISSING')"
```

### Post-Deployment

```bash
# Transaction mined
# Check output for "Contract deployed at: 0x..."

# Verify on Subscan (Paseo)
# https://paseo.subscan.io/account/<contract_address>

# Test basic functionality
cast call <contract_address> "owner()(address)" --rpc-url paseo
```

### Checklist

- [ ] All tests pass locally (`forge test`)
- [ ] Deployed to Previewnet first (if first deployment)
- [ ] Deployed to Paseo with `--slow` flag
- [ ] Logged all deployed addresses
- [ ] Verified on Subscan
- [ ] Tested basic read/write functions
