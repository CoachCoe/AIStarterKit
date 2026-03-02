---
name: code-quality
description: "Enforce minimal code philosophy and exceptional quality. Triggers: quality, refactor, clean, minimal, bloat, simplify, YAGNI"
---

# Code Quality Skill

## When to Activate

- Writing new code
- Reviewing code changes
- Refactoring existing code
- Responding to "improve" or "optimize" requests

---

## Core Philosophy

**Every feature should be implemented with the LEAST amount of code possible.**

The best code is no code. The second best code is minimal code.

**Code must be exceptionally organized.**

Clear structure, logical grouping, consistent patterns. Organization is not optional.

---

## Global Invariants

| Rule | Enforcement | Status |
|------|-------------|--------|
| Least code wins | Fewer lines = better | MANDATORY |
| Exceptional organization | Clear structure, logical grouping | MANDATORY |
| Build only what's requested | No speculative features | MANDATORY |
| Delete unused code | Don't comment out | MANDATORY |
| Three lines > premature abstraction | Keep it simple | MANDATORY |
| Self-documenting code | Comments explain WHY | MANDATORY |
| No code bloat | Trim everything unnecessary | MANDATORY |

---

## Core Principles

### 1. YAGNI — You Aren't Gonna Need It

| ✅ DO | ❌ DON'T |
|-------|---------|
| Implement the requested feature | Add "configurable" options |
| Solve the specific problem | Design for hypothetical futures |
| Write minimal working code | Build "extensible" frameworks |

### 2. The Right Amount of Complexity

| ✅ DO | ❌ DON'T |
|-------|---------|
| Three similar lines of code | Premature helper function |
| Direct implementation | Factory pattern for one class |
| Inline logic where clear | Utility function used once |

### 3. Delete, Don't Comment

| ✅ DO | ❌ DON'T |
|-------|---------|
| `git rm unused-file.ts` | `// TODO: remove later` |
| Remove unused imports | `_unusedVariable` renaming |
| Delete dead branches | `// OLD: previous impl` |

---

## Contrastive Exemplars

### Feature Scope

✅ CORRECT:
```typescript
// User asked: "Add loading state"
function Button({ loading, children }) {
  return (
    <button disabled={loading}>
      {loading ? 'Loading...' : children}
    </button>
  );
}
```

❌ FAIL:
```typescript
// User asked: "Add loading state"
// OVER-ENGINEERED: Added size, variant, icon nobody asked for
function Button({ loading, size, variant, icon, iconPosition, ... }) {
  // 50 lines of configuration
}
```

### Abstraction Timing

✅ CORRECT:
```typescript
// First occurrence - just write it
const date1 = new Date(item1.createdAt).toLocaleDateString();

// Second occurrence - still fine
const date2 = new Date(item2.createdAt).toLocaleDateString();

// Third occurrence - NOW consider extraction
function formatDate(timestamp: number): string {
  return new Date(timestamp).toLocaleDateString();
}
```

❌ FAIL:
```typescript
// First occurrence - premature abstraction
const DateFormatter = {
  format: (timestamp: number, options?: FormatOptions) => {
    // 30 lines of configurability for single use
  }
};
```

---

## Anti-Patterns

| Pattern | Status | Instead |
|---------|--------|---------|
| Speculative features | FORBIDDEN | Build what's requested |
| Commented-out code | FORBIDDEN | Delete (git has history) |
| `_unusedVar` naming | FORBIDDEN | Remove the variable |
| Premature abstraction | FORBIDDEN | Duplicate until clear |
| `// TODO: refactor` | FORBIDDEN | Do it or create issue |
| Wrapper with no logic | FORBIDDEN | Call directly |
