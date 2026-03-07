# Polkadot AI Starter Kit

> Build on Polkadot with AI-assisted development

## Agent Context

**For AI Coding Agents**: Read `.claude/AGENTS.md` FIRST for critical instructions, safety boundaries, and operational context.

**Skill Files**: Domain-specific knowledge is in `.claude/skills/`. Load relevant skills before implementation work.

---

## Project Overview

This is a starter kit for building dApps on Polkadot Asset Hub EVM. It includes pre-configured Claude Code skills for smart contract development, testing, and deployment.

### Key Concepts

- **Asset Hub**: Polkadot's system parachain for asset management with EVM compatibility
- **UUPS Proxy**: Upgradeable contract pattern using OpenZeppelin
- **Paseo**: Polkadot's testnet for development and testing

---

## Architecture

### pnpm Monorepo Structure

```
project/
├── .claude/                     # AI agent configuration
│   ├── AGENTS.md                # Agent constraints (READ FIRST)
│   ├── settings.local.json      # Permissions
│   └── skills/                  # Domain knowledge
├── packages/
│   ├── contracts/               # Solidity contracts (Foundry)
│   │   ├── contracts/
│   │   ├── script/
│   │   ├── test/
│   │   ├── lib/
│   │   └── foundry.toml
│   └── web/                     # Frontend (optional)
│       ├── src/
│       └── package.json
├── CLAUDE.md                    # This file
├── pnpm-workspace.yaml          # Workspace config
├── package.json                 # Root package.json
└── .env                         # Environment variables (NEVER COMMIT)
```

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Monorepo | pnpm workspaces | Fast, disk-efficient |
| Contracts | Solidity 0.8.20+ | EVM compatibility |
| Framework | Foundry | Fast testing, scripting |
| Upgrades | OpenZeppelin UUPS | Battle-tested patterns |
| Network | **Paseo Asset Hub** | Primary target chain |
| Frontend | React/Vite | Minimal, fast |
| Testing | Forge + Vitest | Contracts + Frontend |

### Target Chain

**Primary: Paseo Asset Hub EVM** (testnet) → **Polkadot Asset Hub EVM** (mainnet)

We do NOT use Moonbeam. Asset Hub is the native Polkadot solution for EVM contracts.

---

## Network Configuration

### Development Workflow

```
Local Anvil → Previewnet → Paseo → Mainnet
   (fast)    (no faucet)  (public)  (prod)
```

### Previewnet (Local Development)
- RPC: `https://previewnet.substrate.dev/eth-rpc`
- Pre-funded accounts (Alice, Bob, etc.)
- No faucet needed - ephemeral network
- Web UI: https://previewnet.substrate.dev

### Paseo Testnet (Integration Testing)
- RPC: `https://paseo-asset-hub-eth-rpc.polkadot.io`
- Chain ID: `420420421`
- Block Explorer: https://paseo.subscan.io
- Faucet: https://faucet.polkadot.io

### Polkadot Mainnet (Production)
- RPC: `https://polkadot-asset-hub-eth-rpc.polkadot.io`
- Chain ID: `420420420`
- Block Explorer: https://assethub-polkadot.subscan.io

---

## Coding Standards

### Code Philosophy

**Every feature should be implemented with the least amount of code possible.**

**Code must be exceptionally organized.**

| Principle | Implementation |
|-----------|----------------|
| Least code wins | Minimum code to achieve the goal |
| Exceptional organization | Clear structure, logical grouping |
| No code bloat | Delete anything unused |
| No over-engineering | Build exactly what's requested |
| No premature abstraction | 3 similar lines > 1 premature helper |
| No speculative features | YAGNI (You Aren't Gonna Need It) |
| No wrapper functions | Call directly unless adding real value |

### Solidity

- **Solidity 0.8.20+** for latest features
- **SPDX license identifiers** on every file
- **NatSpec comments** for public functions only
- **OpenZeppelin contracts** for standard patterns
- **UUPS pattern** for upgradeability

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title MyContract
/// @notice Brief description
contract MyContract is Initializable, UUPSUpgradeable {
    // Implementation - keep it minimal
}
```

### TypeScript (Frontend)

- **Strict mode always** (`"strict": true`)
- **No `any`** — use `unknown` and type guards
- **Explicit return types** on exports
- **Minimal dependencies** — justify every `pnpm add`

### Code Quality

- **Least code wins** — if it can be done in fewer lines, do it
- **Delete unused code** — don't comment out, delete it
- **Self-documenting code** — comments explain WHY, not WHAT
- **No premature abstraction** — wait until pattern is clear (rule of 3)

### Git Conventions

- **Conventional commits**: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`
- **Branch naming**: `feat/feature-name`, `fix/bug-description`
- **No direct commits to main**
- **No `Co-Authored-By` lines** — triggers CLA bot checks on GitHub PRs

---

## Testing Standards

### Coverage Requirements

- **Minimum 80% line coverage** for contracts
- **100% for security-critical code** (access control, funds handling)

### Foundry Test Structure

```solidity
contract MyContractTest is Test {
    function setUp() public {
        // Deploy contracts
    }

    function test_HappyPath() public {
        // Test expected behavior
    }

    function test_RevertWhen_InvalidInput() public {
        vm.expectRevert("Error message");
        // Call that should revert
    }

    function testFuzz_WithRandomInput(uint256 value) public {
        vm.assume(value > 0 && value < 1000);
        // Fuzz test
    }
}
```

### Commands

```bash
# Solidity tests
forge test              # Run all tests
forge test -vvv         # Verbose output
forge coverage          # Coverage report

# TypeScript tests (if frontend)
pnpm test               # Run tests
pnpm test:coverage      # Coverage report
```

---

## Development Commands

```bash
# Foundry
forge build             # Compile contracts
forge test              # Run tests
forge test -vvv         # Verbose tests
forge coverage          # Coverage report
forge fmt               # Format Solidity

# Deployment
source .env             # Load environment
forge script script/Deploy.s.sol --rpc-url paseo --broadcast --slow -vvvv

# Frontend (if applicable)
pnpm install            # Install dependencies
pnpm dev                # Start development
pnpm build              # Production build
pnpm lint               # Lint
pnpm typecheck          # TypeScript checking
```

---

## Skill Files

Domain-specific knowledge in `.claude/skills/`:

| Skill | Purpose | Triggers |
|-------|---------|----------|
| `code-quality.md` | Minimal code philosophy | quality, refactor, YAGNI |
| `testing.md` | Test patterns (TypeScript) | test, coverage, spec |
| `security.md` | Security baseline | security, validation, audit |
| `previewnet.md` | Ephemeral dev network | previewnet, local dev, no faucet |
| `asset-hub-evm.md` | Polkadot Asset Hub EVM config | asset hub, polkadot, paseo |
| `upgradeable-contracts.md` | OpenZeppelin UUPS patterns | upgradeable, proxy, UUPS |
| `deploy-contracts/` | Contract deployment workflow | deploy, deployment, mainnet |
| `deploy-frontend/` | Bulletin Chain + DotNS deployment | deploy frontend, dotns, bulletin |
| `dotli/` | dot.li universal resolver ("fourth host") | dot.li, smoldot, helia, link sharing |
| `host-api.md` | Triangle/Host API overview | host api, triangle, product sdk |
| `triangle/` | Full Triangle skill family | spektr, authentication, dotns, service worker |
| `foundry-testing/` | Foundry/Solidity test patterns | forge test, solidity test |
| `mutation-testing/` | Stryker mutation testing | mutation, stryker, test quality |
| `skill-creator/` | Create new skills | create skill, new skill |

**Usage**: Load relevant skills before implementing features in that domain.

**Keeping Skills Updated**: Skills are sourced from reference repositories (Parity, community). Check `.claude/SOURCES.md` for upstream repos and run `/sync-skills` periodically—weekly during active development or before major releases.

For agent operational constraints, see `.claude/AGENTS.md`.
