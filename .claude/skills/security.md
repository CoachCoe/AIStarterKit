---
name: security
description: "Implement security best practices and avoid common vulnerabilities. Triggers: security, validation, audit, input, sanitize, XSS, injection"
---

# Security Skill

## When to Activate

- Handling user input
- Implementing authentication
- Adding dependencies
- Configuring HTTP responses
- Implementing logging
- Any user-facing changes

---

## Global Invariants

| Rule | Enforcement | Status |
|------|-------------|--------|
| Validate all input | Zod/schema validation | MANDATORY |
| No PII in logs | Runtime checks | MANDATORY |
| Audit dependencies | `pnpm audit` in CI | MANDATORY |
| Security headers | Middleware/config | MANDATORY |

---

## Input Validation

### Always Validate

```typescript
import { z } from 'zod';

const UserInputSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  age: z.number().int().min(0).max(150),
});

function createUser(input: unknown) {
  const validated = UserInputSchema.parse(input);
  // Now safe to use
}
```

### Validation Rules

| Type | Constraints |
|------|-------------|
| Strings | Max length, no HTML, pattern match |
| Numbers | Range-checked, no NaN |
| Arrays | Max length, element validation |
| URLs | Valid URL, no javascript: scheme |

---

## Contrastive Exemplars

### Input Handling

✅ CORRECT:
```typescript
// Validate at boundary, use typed result
const input = UserSchema.parse(request.body);
await createUser(input);
```

❌ FAIL:
```typescript
// Trust client input
await createUser(request.body as User);
```

### Logging

✅ CORRECT:
```typescript
logger.error('Login failed', {
  errorCode: error.code,
  attemptCount: attempts,
});
```

❌ FAIL:
```typescript
logger.error('Login failed', {
  email: user.email,      // PII!
  password: user.password, // Credential!
  ip: request.ip,         // PII!
});
```

### Error Messages

✅ CORRECT:
```typescript
// Generic error to client
throw new AppError('Authentication failed');
```

❌ FAIL:
```typescript
// Information leak
throw new Error(`User ${email} not found in database`);
throw new Error(`Password incorrect for user ${userId}`);
```

---

## HTTP Security Headers

```typescript
const securityHeaders = [
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=()' },
];

// If using CSP
const csp = [
  "default-src 'self'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline'",
].join('; ');
```

---

## Dependency Security

### Audit Process

```bash
# Run on every install
pnpm audit

# CI must pass with zero critical/high
pnpm audit --audit-level=high
```

### Dependency Rules

| Rule | Reason |
|------|--------|
| Justify every dependency | Attack surface |
| Lock versions | Reproducibility |
| Review changelogs | Breaking changes |
| Check maintenance | Bus factor |

---

## Secure Coding Checklist

### Before Every PR

- [ ] All input validated
- [ ] No PII in logs
- [ ] No hardcoded secrets
- [ ] No `eval()` or `innerHTML`
- [ ] `pnpm audit` passes

### For Auth Changes

- [ ] Password hashing (bcrypt/argon2)
- [ ] Constant-time comparison
- [ ] Rate limiting
- [ ] Session expiration

---

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| `eval()` | FORBIDDEN | Code injection |
| `innerHTML` | FORBIDDEN | XSS |
| Trust client input | FORBIDDEN | All input is hostile |
| Log PII | FORBIDDEN | Compliance/privacy |
| Hardcode secrets | FORBIDDEN | Source control leak |
| SQL string concat | FORBIDDEN | SQL injection |
| Disable HTTPS | FORBIDDEN | MitM attacks |
