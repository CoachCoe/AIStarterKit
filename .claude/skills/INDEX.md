# Skill Index

Quick reference for finding the right skill. See `AGENTS.md` for loading protocol.

---

## By Domain

### Smart Contracts

| Skill | Purpose |
|-------|---------|
| `upgradeable-contracts.md` | UUPS proxy patterns, OpenZeppelin |
| `foundry-testing/SKILL.md` | Solidity test patterns, mocks, fuzz |
| `deploy-contracts/SKILL.md` | Deployment workflow, scripts |
| `asset-hub-evm.md` | Chain config, RPC endpoints |

### Frontend / Triangle

| Skill | Purpose |
|-------|---------|
| `triangle/OVERVIEW.md` | **Start here** - architecture, concepts |
| `triangle/product-sdk.md` | Build products for Triangle hosts |
| `triangle/authentication.md` | Wallet auth (Papp + extensions) |
| `triangle/spektr-manager.md` | Container orchestration for hosts |
| `triangle/dotns-resolution.md` | Resolve .dot domains |
| `triangle/service-worker.md` | IPFS caching patterns |
| `triangle/static-export.md` | Static build requirements |
| `deploy-frontend/SKILL.md` | Bulletin + DotNS deployment |
| `dotli/SKILL.md` | Client-side resolution |

### Infrastructure & Secrets

| Skill | Purpose |
|-------|---------|
| `p1p-secrets/SKILL.md` | Secret management via p1p CLI |
| `cli-setup.md` | Install p1p + dotns CLIs |
| `locker-structure.md` | p1p locker organization |
| `previewnet.md` | Ephemeral dev network |

### Quality & Testing

| Skill | Purpose |
|-------|---------|
| `code-quality.md` | Minimal code philosophy, metrics |
| `testing.md` | TypeScript test patterns |
| `security.md` | Security baseline, validation |
| `mutation-testing/SKILL.md` | Stryker mutation testing |
| `error-handling.md` | Error patterns (Solidity + TS) |

### Meta / Workflows

| Skill | Purpose |
|-------|---------|
| `end-to-end-deployment.md` | Full workflow guide |
| `skill-creator/SKILL.md` | Create new skills |
| `host-api.md` | Triangle skill family index |

---

## By Trigger Word

| Trigger | Skill |
|---------|-------|
| anvil, local, unit test | `previewnet.md` |
| auth, wallet, papp, extension | `triangle/authentication.md` |
| bulletin, dotns, .dot | `deploy-frontend/SKILL.md` |
| cache, offline, service worker | `triangle/service-worker.md` |
| coverage, forge test | `foundry-testing/SKILL.md` |
| credentials, env vars, secrets | `p1p-secrets/SKILL.md` |
| deploy, deployment | `deploy-contracts/` or `deploy-frontend/` |
| dot.li, smoldot, helia | `dotli/SKILL.md` |
| error, exception, revert | `error-handling.md` |
| host, triangle, spektr | `triangle/OVERVIEW.md` |
| iframe, embed, product | `triangle/product-sdk.md` |
| ipfs, static, ssr | `triangle/static-export.md` |
| locker, p1p | `locker-structure.md`, `p1p-secrets/` |
| mutation, stryker | `mutation-testing/SKILL.md` |
| paseo, asset hub, polkadot | `asset-hub-evm.md` |
| previewnet, ephemeral | `previewnet.md` |
| proxy, upgradeable, UUPS | `upgradeable-contracts.md` |
| quality, refactor, YAGNI | `code-quality.md` |
| resolution, contenthash | `triangle/dotns-resolution.md` |
| security, validation, audit | `security.md` |
| skill, create skill | `skill-creator/SKILL.md` |
| test, spec, vitest | `testing.md` |

---

## Decision Tree

```
What are you building?
│
├─ Smart contract
│  ├─ New upgradeable contract → upgradeable-contracts.md
│  ├─ Writing tests → foundry-testing/SKILL.md
│  └─ Deploying → deploy-contracts/SKILL.md
│
├─ Frontend / dApp
│  ├─ Runs in Triangle host → triangle/OVERVIEW.md (start here)
│  │  ├─ Building the host → triangle/spektr-manager.md
│  │  └─ Building a product → triangle/product-sdk.md
│  └─ Deploying to Bulletin → deploy-frontend/SKILL.md
│
├─ Infrastructure
│  ├─ Managing secrets → p1p-secrets/SKILL.md
│  ├─ Local development → previewnet.md
│  └─ Installing CLIs → cli-setup.md
│
└─ Quality / Review
   ├─ Code review → code-quality.md
   ├─ Security review → security.md
   └─ Test quality → mutation-testing/SKILL.md
```

---

## Skill Families

Some skills are organized in directories with multiple related files:

| Family | Files | Start With |
|--------|-------|------------|
| `triangle/` | 7 skills | `OVERVIEW.md` |
| `deploy-contracts/` | SKILL.md + references | `SKILL.md` |
| `deploy-frontend/` | SKILL.md | `SKILL.md` |
| `p1p-secrets/` | SKILL.md | `SKILL.md` |
| `dotli/` | SKILL.md + references | `SKILL.md` |
| `foundry-testing/` | SKILL.md | `SKILL.md` |
| `mutation-testing/` | SKILL.md | `SKILL.md` |
| `skill-creator/` | SKILL.md | `SKILL.md` |
