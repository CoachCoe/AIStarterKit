---
name: testing
description: "Implement effective testing patterns and maintain coverage. Triggers: test, coverage, mutation, spec, unit, integration"
---

# Testing Skill

## When to Activate

- Writing new tests
- Improving test coverage
- Setting up test infrastructure
- Evaluating test quality

---

## Global Invariants

| Rule | Enforcement | Status |
|------|-------------|--------|
| 80%+ line coverage | CI gate | MANDATORY |
| 100% for security code | Audit requirement | MANDATORY |
| No test without assertions | Mutation testing catches | MANDATORY |
| Descriptive test names | Self-documenting | MANDATORY |

---

## Test Naming

### Pattern: `it('should <expected behavior> when <condition>')`

✅ CORRECT:
```typescript
it('should return null when user not found')
it('should throw ValidationError when input is empty')
it('should emit event when status changes')
```

❌ FAIL:
```typescript
it('test 1')
it('works')
it('handles error')
```

---

## Test Structure

### AAA Pattern: Arrange, Act, Assert

```typescript
it('calculates total correctly', () => {
  // Arrange
  const items = [{ price: 10 }, { price: 20 }];

  // Act
  const total = calculateTotal(items);

  // Assert
  expect(total).toBe(30);
});
```

### Describe Blocks

```typescript
describe('UserService', () => {
  describe('createUser', () => {
    it('creates user with valid data', () => { ... });
    it('throws when email already exists', () => { ... });
    it('hashes password before storing', () => { ... });
  });

  describe('deleteUser', () => {
    it('removes user from database', () => { ... });
    it('throws when user not found', () => { ... });
  });
});
```

---

## Contrastive Exemplars

### Strong Assertions

✅ CORRECT:
```typescript
// Assert specific values
expect(result).toBe(30);
expect(user.email).toBe('test@example.com');
expect(items).toHaveLength(3);
```

❌ FAIL:
```typescript
// Weak assertions that miss bugs
expect(result).toBeDefined();
expect(user).toBeTruthy();
expect(items.length).toBeGreaterThan(0);
```

### Edge Cases

✅ CORRECT:
```typescript
describe('validateAge', () => {
  it('accepts age 18', () => {
    expect(validateAge(18)).toBe(true);
  });

  it('rejects age 17', () => {
    expect(validateAge(17)).toBe(false);
  });

  it('rejects negative age', () => {
    expect(validateAge(-1)).toBe(false);
  });

  it('rejects non-integer age', () => {
    expect(validateAge(18.5)).toBe(false);
  });
});
```

❌ FAIL:
```typescript
describe('validateAge', () => {
  it('validates age', () => {
    expect(validateAge(25)).toBe(true);
    // Missing boundary tests!
  });
});
```

---

## Coverage Types

| Type | Target | Catches |
|------|--------|---------|
| Line coverage | 80% | Untouched code |
| Branch coverage | 75% | Missing conditions |
| Mutation score | 80% | Weak assertions |

---

## Mutation Testing Basics

Traditional coverage: "Did this line run?"
Mutation testing: "Would tests catch a bug here?"

### Example

```typescript
// Original
function isAdult(age: number): boolean {
  return age >= 18;
}

// Mutant: age > 18 (changed >= to >)
// If tests pass with mutant, they're weak!
```

### Fix Weak Tests

```typescript
// Before: passes with mutant
it('returns true for adult', () => {
  expect(isAdult(25)).toBe(true);
});

// After: catches mutant
it('returns true for exactly 18', () => {
  expect(isAdult(18)).toBe(true);
});

it('returns false for 17', () => {
  expect(isAdult(17)).toBe(false);
});
```

---

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Test without assertions | FORBIDDEN | 0% bug detection |
| `expect(x).toBeDefined()` only | FORBIDDEN | Misses value bugs |
| Hardcoded test data | CAUTION | Use factories |
| Testing implementation | FORBIDDEN | Test behavior |
| Skipped tests (`it.skip`) | FORBIDDEN | Fix or delete |
