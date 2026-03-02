---
name: skill-creator
description: "Create new Claude Code skills. Triggers: create skill, new skill, add skill"
---

# Skill Creator

## When to Activate

- Creating a new skill for this repo
- Reviewing skill structure
- Updating existing skills

## Skill Template

```markdown
---
name: skill-name
description: "Action verb + outcome. Triggers: keyword1, keyword2"
---

# Skill Title

## When to Activate

- Specific trigger condition 1
- Specific trigger condition 2

## Global Invariants

| Rule | Enforcement |
|------|-------------|
| Critical rule 1 | REQUIRED |
| Critical rule 2 | FORBIDDEN |

## Core Content

[Tables and concise guidance - NO verbose prose]

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Bad practice 1 | FORBIDDEN | Why it fails |
| Bad practice 2 | FORBIDDEN | Why it fails |
```

## Rules

| Rule | Enforcement |
|------|-------------|
| Place in `.claude/skills/{name}/SKILL.md` | REQUIRED |
| Include frontmatter with name + description | REQUIRED |
| Add trigger keywords in description | REQUIRED |
| Use tables over prose | REQUIRED |
| Keep under 250 lines | REQUIRED |
| Imperative density >= 5% (MUST/REQUIRED/FORBIDDEN) | REQUIRED |
| Include "When to Activate" section | REQUIRED |
| Include "Anti-Patterns" section | REQUIRED |
| No conversational filler | FORBIDDEN |
| No duplicate examples | FORBIDDEN |

## Naming Convention

| Type | Format | Example |
|------|--------|---------|
| Skill name | kebab-case | `deploy-contracts` |
| Directory | `.claude/skills/{name}/` | `.claude/skills/deploy-contracts/` |
| Main file | `SKILL.md` | Always uppercase |

## Description Format

```
"{Action verb} {outcome}. Triggers: {keyword1}, {keyword2}, {keyword3}"
```

Examples:
- `"Deploy contracts to Polkadot Asset Hub. Triggers: deploy, deployment, paseo"`
- `"Foundry testing patterns for Solidity. Triggers: test, testing, forge test"`

## Imperative Words

Use these for enforcement:
- **MUST** / **REQUIRED** - Mandatory
- **MUST NOT** / **FORBIDDEN** - Prohibited
- **SHOULD** - Recommended (use sparingly)
- **NEVER** - Absolute prohibition

## Anti-Patterns

| Pattern | Status | Reason |
|---------|--------|--------|
| Verbose explanations | FORBIDDEN | Use tables |
| Missing triggers | FORBIDDEN | Skills won't activate |
| No anti-patterns section | FORBIDDEN | Misuse not prevented |
| Prose over tables | FORBIDDEN | Wastes tokens |
| Skills >250 lines | FORBIDDEN | Move detail to references/ |
