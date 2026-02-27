# Project Name

> Brief tagline describing your project

## Agent Context

**For AI Coding Agents**: Read `.claude/AGENTS.md` FIRST for critical instructions, safety boundaries, and operational context.

**Skill Files**: Domain-specific knowledge is in `.claude/skills/`. Load relevant skills before implementation work.

---

## Project Overview

<!-- Describe what this project does, its purpose, and key features -->

This project is...

### Key Concepts

<!-- Define important domain terms -->

- **Term 1**: Definition
- **Term 2**: Definition
- **Term 3**: Definition

---

## Architecture

### Directory Structure

```
project/
├── .claude/                     # AI agent configuration
│   ├── AGENTS.md                # Agent constraints (READ FIRST)
│   ├── settings.local.json      # Permissions
│   ├── skills/                  # Domain knowledge
│   └── commands/                # Reusable workflows
├── CLAUDE.md                    # This file
├── src/                         # Source code
│   ├── app/                     # Application code
│   ├── lib/                     # Utilities
│   └── types/                   # TypeScript types
├── tests/                       # Test files
└── docs/                        # Documentation
```

### Technology Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Language | TypeScript | Type safety |
| Framework | <!-- Your framework --> | <!-- Why --> |
| Testing | <!-- Your test framework --> | <!-- Why --> |
| CI/CD | GitHub Actions | Standard |

---

## Coding Standards

### TypeScript

- **Strict mode always** (`"strict": true`)
- **No `any`** — use `unknown` and type guards
- **No `as` assertions** unless documented
- **Explicit return types** on exports
- **Branded types** for domain IDs

```typescript
// Branded types for domain safety
type UserId = string & { readonly __brand: 'UserId' };

// Explicit return types
export function getUser(id: UserId): Promise<User | null> { ... }
```

### Code Quality

- **Build only what's requested** — no speculative features
- **Delete unused code** — don't comment out
- **Self-documenting code** — comments explain WHY, not WHAT
- **No premature abstraction** — three similar lines > one premature helper

### Error Handling

- **Never swallow errors** — log and surface meaningfully
- **Boundary errors at the edge** — ErrorBoundary, middleware
- **Structured logging** — no `console.log` in production

### Git Conventions

- **Conventional commits**: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`
- **Branch naming**: `feat/feature-name`, `fix/bug-description`
- **No direct commits to main**

---

## Testing Standards

### Coverage Requirements

- **Minimum 80% line coverage**
- **100% for security-critical code**

### Test Structure

```typescript
describe('Component', () => {
  describe('rendering', () => {
    it('renders expected content', () => { ... });
  });

  describe('behavior', () => {
    it('handles user interaction', () => { ... });
  });

  describe('edge cases', () => {
    it('handles empty state', () => { ... });
  });
});
```

### Commands

```bash
pnpm test              # Run all tests
pnpm test:coverage     # Coverage report
pnpm test:mutation     # Mutation testing (if configured)
```

---

## Development Commands

```bash
# Setup
pnpm install           # Install dependencies
pnpm dev               # Start development

# Quality
pnpm lint              # Lint (must pass with zero warnings)
pnpm typecheck         # TypeScript checking
pnpm format            # Format code

# Testing
pnpm test              # Run tests
pnpm test:coverage     # Coverage report

# Build
pnpm build             # Production build
```

---

## Skill Files

Domain-specific knowledge in `.claude/skills/`:

| Skill | Purpose | Triggers |
|-------|---------|----------|
| `code-quality.md` | Minimal code philosophy | quality, refactor, YAGNI |
| `testing.md` | Test patterns | test, coverage, mutation |
| `security.md` | Security baseline | security, validation, audit |

<!-- Add your domain-specific skills here -->

**Usage**: Load relevant skills before implementing features in that domain.

For agent operational constraints, see `.claude/AGENTS.md`.
