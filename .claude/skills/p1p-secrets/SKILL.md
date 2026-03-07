---
name: p1p-secrets
description: "Manage secrets for dApps using p1p CLI. Triggers: p1p, secrets, env vars, credentials, password manager"
---

# P1P Secrets Management

## When to Activate

- Storing API keys, database passwords, or credentials for dApps
- Creating `.env.p1p` template files for projects
- Injecting secrets into development or CI/CD workflows
- Setting up secrets for Triangle/Host API deployments

## Global Invariants

| Rule | Enforcement |
|------|-------------|
| Never commit plaintext secrets | REQUIRED |
| Use `.env.p1p` templates (safe to commit) | REQUIRED |
| Sign in before accessing secrets | REQUIRED |
| Use `p1p run` for development (memory-only) | REQUIRED |
| Use `p1p inject` only for CI/CD pipelines | REQUIRED |
| Never create lockers/items without explicit request | FORBIDDEN |

## Prerequisites

1. **p1p CLI installed** from polkadot-1p repo
2. **Wallet with signed session** (keyfile, mnemonic, or web auth)
3. **Locker created** with entries for your secrets

## URI Format

**Pattern:** `p1p://[locker]/[item]/[field]`

| Component | Description | Example |
|-----------|-------------|---------|
| `locker` | Locker name or ID | `dev-secrets` |
| `item` | Entry title or ID | `postgres-db` |
| `field` | Field to retrieve | `password` |

**Standard Fields:**

| Field | Returns |
|-------|---------|
| `password` | Password field |
| `username` | Username field |
| `url` | First URL |
| `urls` | All URLs (newline-separated) |
| `notes` | Notes field |
| `totp` | Current TOTP code |
| `customFields.<key>` | Custom field by key |

## Template File Format (.env.p1p)

```env
# Plain values (safe to commit)
NODE_ENV=development
PORT=3000

# Secret references (resolved at runtime)
DATABASE_URL=p1p://app-secrets/postgres/url
API_KEY=p1p://app-secrets/external-api/customFields.api_key
DB_PASSWORD=p1p://app-secrets/postgres/password

# Host API / Triangle deployment
HOST_API_KEY=p1p://deployment/host-api/key
BULLETIN_MNEMONIC=p1p://deployment/bulletin/mnemonic
```

## Authentication

```bash
# Option 1: Web auth (recommended - shares session with browser)
p1p signin --web

# Option 2: Keyfile
p1p signin --keyfile ~/.polkadot/my-wallet.json

# Option 3: Mnemonic (interactive prompt)
p1p signin --mnemonic

# Check status
p1p status
p1p whoami
```

**Session:** 30-minute TTL, stored in OS keyring. Auto-extends on activity.

## Development Workflow

### Step 1: Create Template

```bash
# Create .env.p1p in project root
cat > .env.p1p << 'EOF'
NODE_ENV=development
PORT=3000
DATABASE_URL=p1p://dev-secrets/postgres/url
API_KEY=p1p://dev-secrets/api/key
EOF
```

### Step 2: Run with Secrets

```bash
# Sign in once per session
p1p signin --web

# Run command with injected secrets (memory-only)
p1p run --env-file .env.p1p -- npm start
p1p run --env-file .env.p1p -- forge script Deploy.s.sol
```

### Step 3: Read Individual Secrets

```bash
# Read specific secret
p1p read "p1p://dev-secrets/postgres/password"

# Copy to clipboard (auto-clears in 30s)
p1p read "p1p://dev-secrets/api/key" --clipboard
```

## CI/CD Integration

```yaml
# GitHub Actions example
- name: Install p1p
  run: npm install -g @locker/cli

- name: Sign in
  run: p1p signin --seed "${{ secrets.P1P_SEED }}"

- name: Inject secrets to .env
  run: p1p inject -e .env.p1p -o .env

- name: Deploy
  run: pnpm run deploy
```

## Triangle/Host API Integration

For dApps deployed to Triangle hosts:

```env
# .env.p1p for Triangle deployment
# Bulletin Chain credentials
DOTNS_MNEMONIC=p1p://deployment/dotns/customFields.mnemonic

# Host API credentials (if using authenticated endpoints)
HOST_API_TOKEN=p1p://deployment/host-api/token

# Contract deployment
DEPLOYER_PRIVATE_KEY=p1p://deployment/contracts/customFields.private_key
```

**Workflow:**
```bash
# 1. Sign in
p1p signin --mnemonic

# 2. Deploy contracts with secrets
p1p run --env-file .env.p1p -- forge script script/Deploy.s.sol --broadcast

# 3. Deploy frontend to Bulletin/DotNS
p1p run --env-file .env.p1p -- bun run deploy-frontend
```

## DotNS Frontend Deployment

For deploying frontends to Bulletin Chain with dotns CLI:

```bash
# 1. Sign in to p1p
p1p signin --mnemonic

# 2. Export mnemonic for dotns CLI
export DOTNS_MNEMONIC=$(p1p read "p1p://<locker>/dotns/customFields.mnemonic" -n)

# 3. Build frontend
pnpm build

# 4. Upload to Bulletin
bun run src/cli/index.ts bulletin upload ./dist \
  --parallel --concurrency 5 --print-contenthash \
  -m "$DOTNS_MNEMONIC"

# 5. Set content hash on domain (use CID from step 4)
bun run src/cli/index.ts content set <domain-name> <CID> \
  -m "$DOTNS_MNEMONIC"
```

**Note:** The mnemonic stays in memory only — never written to disk.

## CLI Commands Reference

| Command | Purpose |
|---------|---------|
| `p1p signin [--web\|--keyfile\|--mnemonic]` | Authenticate |
| `p1p signout` | Clear session |
| `p1p status` | Show session status |
| `p1p read <uri>` | Read single secret |
| `p1p run --env-file <file> -- <cmd>` | Run with injected secrets |
| `p1p inject -e <file> -o <output>` | Write resolved .env |
| `p1p item list -l <locker>` | List items in locker |
| `p1p item create -l <locker> -t <title>` | Create item |
| `p1p locker list` | List lockers |
| `p1p generate` | Generate secure password |

## Locker/Item Management

**Only create when explicitly requested:**

```bash
# Create locker
p1p locker create -n "my-app-secrets"

# Create item with fields
p1p item create -l "my-app-secrets" -t "postgres" \
  --category login \
  --field url="postgres://..." \
  --field password="..."

# Generate password
p1p item create -l "my-app-secrets" -t "api-key" \
  --category custom \
  --generate-password
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Commit `.env` with secrets | FORBIDDEN | Security risk |
| Use `p1p inject` for development | FORBIDDEN | Secrets on disk |
| Create locker without explicit request | FORBIDDEN | User must manage their vault |
| Hardcode secrets in scripts | FORBIDDEN | Use p1p:// URIs |
| Skip authentication check | FORBIDDEN | Commands will fail |
| Share seed phrase in CI logs | FORBIDDEN | Mask all credentials |
