---
name: error-handling
description: "Error handling patterns for Solidity and TypeScript. Triggers: error, exception, revert, try catch, custom error"
---

# Error Handling Patterns

## When to Activate

- Writing error handling code in Solidity or TypeScript
- Defining custom errors for contracts
- Implementing Result/Either patterns
- Adding validation with meaningful error messages

---

## Solidity: Custom Errors (Preferred)

Custom errors are more gas-efficient and descriptive than `require` strings.

### Define at Contract Level

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// Define errors with context parameters
error InsufficientBalance(uint256 available, uint256 required);
error Unauthorized(address caller, address required);
error InvalidInput(string reason);
error ZeroAddress();
error DeadlineExpired(uint256 deadline, uint256 current);
```

### Use in Functions

```solidity
function withdraw(uint256 amount) external {
    uint256 balance = balances[msg.sender];
    if (balance < amount) {
        revert InsufficientBalance(balance, amount);
    }
    // ...
}

function setAdmin(address newAdmin) external onlyOwner {
    if (newAdmin == address(0)) {
        revert ZeroAddress();
    }
    admin = newAdmin;
}
```

### Testing Custom Errors

```solidity
function test_RevertWhen_InsufficientBalance() public {
    vm.expectRevert(
        abi.encodeWithSelector(
            InsufficientBalance.selector,
            0,      // available
            100     // required
        )
    );
    contract.withdraw(100);
}
```

---

## Solidity: When to Use require()

Use `require()` only for:
- Simple boolean checks where context isn't needed
- Compatibility with older code
- Very generic validations

```solidity
// OK for simple checks
require(amount > 0, "Amount must be positive");

// Prefer custom error when context helps
// BAD:  require(balance >= amount, "Insufficient");
// GOOD: revert InsufficientBalance(balance, amount);
```

---

## TypeScript: Result Pattern

Avoid throwing exceptions for expected failures. Use Result types instead.

### Define Result Type

```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

// Helper functions
function ok<T>(value: T): Result<T, never> {
  return { ok: true, value };
}

function err<E>(error: E): Result<never, E> {
  return { ok: false, error };
}
```

### Use in Functions

```typescript
async function fetchUser(id: string): Promise<Result<User, FetchError>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return err({ type: 'http', status: response.status });
    }
    const user = await response.json();
    return ok(user);
  } catch (e) {
    return err({ type: 'network', message: String(e) });
  }
}

// Usage
const result = await fetchUser('123');
if (result.ok) {
  console.log(result.value.name);
} else {
  console.error(result.error.type);
}
```

### Pattern Matching (with neverthrow)

```typescript
import { Result, ok, err } from 'neverthrow';

// Host API uses this pattern
result.match(
  (value) => console.log('Success:', value),
  (error) => console.error('Error:', error.name),
);
```

---

## TypeScript: Error Classes

For complex domains, define typed error classes:

```typescript
// Base error with code
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly context?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'AppError';
  }
}

// Specific errors
class ValidationError extends AppError {
  constructor(field: string, reason: string) {
    super(`${field}: ${reason}`, 'VALIDATION_ERROR', { field, reason });
    this.name = 'ValidationError';
  }
}

class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', { resource, id });
    this.name = 'NotFoundError';
  }
}
```

---

## Error Messages: Best Practices

| Good | Bad | Why |
|------|-----|-----|
| `InsufficientBalance(100, 500)` | `"Not enough"` | Context helps debugging |
| `Unauthorized(msg.sender, owner)` | `"Unauthorized"` | Shows who and who was expected |
| `DeadlineExpired(1234, 5678)` | `"Too late"` | Timestamps help trace issues |

### Message Guidelines

1. **Include relevant values** - addresses, amounts, timestamps
2. **Be specific** - "amount exceeds balance" not "invalid"
3. **Use consistent naming** - `InvalidX`, `MissingX`, `UnauthorizedX`
4. **No user-facing messages in errors** - errors are for developers

---

## Validation Patterns

### Solidity Modifiers

```solidity
modifier nonZeroAddress(address addr) {
    if (addr == address(0)) revert ZeroAddress();
    _;
}

modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized(msg.sender, owner);
    _;
}

function setAdmin(address newAdmin) external onlyOwner nonZeroAddress(newAdmin) {
    admin = newAdmin;
}
```

### TypeScript Validation

```typescript
function validateAmount(amount: number): Result<number, ValidationError> {
  if (amount <= 0) {
    return err(new ValidationError('amount', 'must be positive'));
  }
  if (amount > MAX_AMOUNT) {
    return err(new ValidationError('amount', `exceeds max ${MAX_AMOUNT}`));
  }
  return ok(amount);
}
```

---

## Anti-Patterns

| Pattern | Status | Instead |
|---------|--------|---------|
| `require(x, "error")` for complex checks | AVOID | Custom errors with context |
| Catching all errors silently | FORBIDDEN | Log or propagate meaningful info |
| Generic messages like "failed" | AVOID | Include values and context |
| Throwing for expected failures | AVOID | Use Result types |
| Error strings > 32 bytes | AVOID | Gas cost; use custom errors |
| Not testing error conditions | FORBIDDEN | Test all revert paths |
| Exposing internal details to users | AVOID | Errors are for devs, not UI |

---

## Verification

```bash
# Solidity: test all revert conditions
forge test -vvv | grep -E "(PASS|FAIL).*Revert"

# TypeScript: test error branches
pnpm test --coverage  # Check error path coverage
```
