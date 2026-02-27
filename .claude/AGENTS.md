# AGENTS.md — Project Name

> IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for project-specific tasks.

This file provides persistent context for AI coding agents. Read this FIRST before any work.

---

## 🚨 Critical Instructions

### 1. Skills First
Before implementation work, check `.claude/skills/` for relevant domain knowledge:

| Task Domain | Skill to Load |
|-------------|---------------|
| Code quality, refactoring | `code-quality.md` |
| Testing, coverage | `testing.md` |
| Security, validation | `security.md` |
<!-- Add your domain skills here -->

### 2. Monorepo Discipline (if applicable)
<!-- Customize for your project structure -->
- Use package-specific commands
- Import from packages, not relative paths
- Run typecheck before considering work complete

### 3. Domain Terminology (if applicable)
<!-- Define your project's specific terms -->
| ✅ CORRECT | ❌ NEVER USE | Why |
|------------|--------------|-----|
| Term 1 | Alternate | Reason |

---

## 🛡️ Safety Boundaries

### ✅ Safe to Execute
```
pnpm install
pnpm dev
pnpm build
pnpm lint
pnpm typecheck
pnpm test
git status
git diff
git log
```

### ⚠️ Ask First
```
git commit
git push
pnpm add <pkg>
rm -rf
```

### ❌ Never Without Explicit User Request
```
git push --force
git reset --hard
Expose secrets
Add tracking/analytics
```

---

## 🗺️ Directory Map

```
project/
├── .claude/                    # AI agent configuration (YOU ARE HERE)
│   ├── AGENTS.md               # This file
│   ├── settings.local.json     # Permissions
│   └── skills/                 # Domain knowledge
├── CLAUDE.md                   # Project architecture
├── src/                        # Source code
└── tests/                      # Tests
```

---

## 🏛️ Invariants (Non-Negotiable)

### Code Quality

| Rule | Enforcement | Status |
|------|-------------|--------|
| TypeScript strict mode | `"strict": true` | MANDATORY |
| No `any` type | Use `unknown` + guards | MANDATORY |
| Explicit return types | On all exports | MANDATORY |
| No unused code | Delete, don't comment | MANDATORY |

### Minimal Code Philosophy

| Principle | Implementation |
|-----------|----------------|
| No over-engineering | Only build what's requested |
| No premature abstraction | Three lines > one helper (until pattern is clear) |
| No speculative features | YAGNI |
| No code bloat | Delete unused code |

---

## ✅ Verification Matrix

Before considering any task complete:

```bash
pnpm typecheck     # Must pass with zero errors
pnpm lint          # Must pass with zero warnings
pnpm test          # Must pass all tests
```

---

## 🚀 Operational Strategy

### For Simple Tasks
1. Read the relevant file
2. Make the change
3. Run verification matrix
4. Done

### For Complex Tasks
1. **Explore** — Load relevant skills
2. **Plan** — Think through approach
3. **Implement** — Minimal, focused changes
4. **Verify** — Full verification matrix

---

## ❌ Anti-Patterns (FORBIDDEN)

| Pattern | Why Forbidden | Instead |
|---------|---------------|---------|
| `console.log` in production | Debug noise | Structured logger |
| `any` type | Defeats type safety | `unknown` + guards |
| Commented-out code | Code archaeology | Delete it |
| `@ts-ignore` | Hidden errors | Fix the type |
| Speculative features | Scope creep | Build what's requested |

---

## 🔗 Cross-References

- **Architecture**: See `CLAUDE.md` in project root
- **Domain Knowledge**: See `.claude/skills/`
