---
name: mutation-testing
description: "Mutation testing with Stryker for TypeScript. Triggers: mutation, stryker, test quality"
---

# Mutation Testing

## When to Activate

- Evaluating test suite effectiveness
- Setting up Stryker for TypeScript/React
- Interpreting mutation test results
- Improving tests based on surviving mutants

## What is Mutation Testing?

| Concept | Explanation |
|---------|-------------|
| Mutant | Automated code change (e.g., `>=` -> `>`) |
| Killed | Test failed = mutant detected = good |
| Survived | Tests passed = gap in coverage = bad |
| Score | % of mutants killed (higher = better tests) |

## Why Not Just Code Coverage?

| Metric | What It Tells You |
|--------|-------------------|
| Code Coverage | Lines executed by tests |
| Mutation Score | Lines actually *verified* by tests |

A test without assertions has 100% coverage but 0% mutation score.

## Setup

```bash
# Install Stryker
pnpm add -D @stryker-mutator/core @stryker-mutator/typescript-checker @stryker-mutator/vitest-runner

# Initialize config
pnpm stryker init
```

## Configuration (stryker.config.json)

```json
{
  "$schema": "./node_modules/@stryker-mutator/core/schema/stryker-schema.json",
  "packageManager": "pnpm",
  "testRunner": "vitest",
  "checkers": ["typescript"],
  "tsconfigFile": "tsconfig.json",
  "mutate": [
    "src/**/*.ts",
    "src/**/*.tsx",
    "!src/**/*.test.ts",
    "!src/**/*.spec.ts"
  ],
  "reporters": ["html", "clear-text", "progress"],
  "coverageAnalysis": "perTest",
  "timeoutMS": 10000
}
```

## Running Mutation Tests

```bash
# Full run
pnpm stryker run

# Specific files
pnpm stryker run --mutate "src/lib/schemas/*.ts"

# Incremental (faster, only changed files)
pnpm stryker run --incremental
```

## Common Mutators

| Mutator | Original | Mutated |
|---------|----------|---------|
| BinaryOperator | `a >= b` | `a > b`, `a < b` |
| ConditionalExpression | `a && b` | `true`, `false` |
| EqualityOperator | `===` | `!==` |
| StringLiteral | `"text"` | `""` |
| ArrayDeclaration | `[a, b]` | `[]` |
| BooleanLiteral | `true` | `false` |

## Interpreting Results

```
Mutant survived: src/lib/schemas/user.ts:42:15
Mutator: EqualityOperator
-    if (value === 0) {
+    if (value !== 0) {
```

**Action:** Add test that verifies behavior when `value === 0`.

## Target Scores

| Score | Quality |
|-------|---------|
| < 60% | Poor - significant test gaps |
| 60-80% | Acceptable - common for UI code |
| > 80% | Good - well-tested logic |
| > 90% | Excellent - critical paths covered |

## Package.json Scripts

```json
{
  "scripts": {
    "test:mutation": "stryker run",
    "test:mutation:incremental": "stryker run --incremental"
  }
}
```

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Mutating test files | FORBIDDEN | Config excludes `*.test.ts` |
| Running on full codebase first | FORBIDDEN | Start with critical paths |
| Ignoring survived mutants | FORBIDDEN | Each is a potential bug |
| 100% score goal | FORBIDDEN | Diminishing returns past 85% |
