# AI Starter Kit

A production-ready Claude Code configuration template based on best practices from multiple Polkadot ecosystem projects.

## What's Included

```
AIStarterKit/
├── .claude/
│   ├── AGENTS.md                 # Agent constraints (READ FIRST)
│   ├── settings.local.json       # Permissions
│   ├── skills/                   # Domain knowledge skills
│   │   ├── code-quality.md       # Minimal code philosophy
│   │   ├── testing.md            # Test patterns
│   │   └── security.md           # Security baseline
│   └── commands/
│       └── sync-skills.md        # Skill sync workflow
├── CLAUDE.md                     # Project architecture template
├── scripts/
│   ├── setup.sh                  # Initialize new project
│   └── skill-sync.sh             # Check reference repos for updates
└── README.md                     # This file
```

## Quick Start

### Option 1: Copy to Existing Project

```bash
# Copy .claude directory to your project
cp -r /path/to/AIStarterKit/.claude /path/to/your/project/

# Copy CLAUDE.md and customize
cp /path/to/AIStarterKit/CLAUDE.md /path/to/your/project/

# Edit CLAUDE.md to match your project
```

### Option 2: Use Setup Script

```bash
cd /path/to/your/project
/path/to/AIStarterKit/scripts/setup.sh
```

## Configuration

### 1. Customize CLAUDE.md

Update these sections for your project:
- Project Overview
- Architecture (directory structure)
- Technology Stack
- Design System (if frontend)
- Coding Standards
- Testing Standards

### 2. Customize AGENTS.md

Update these sections:
- Skills routing table (add your domain skills)
- Safety boundaries (project-specific)
- Invariants (your non-negotiables)
- Verification matrix

### 3. Add Domain Skills

Create skills in `.claude/skills/` for your project domains:

```markdown
---
name: my-skill
description: "What this skill does. Triggers: keyword1, keyword2"
---

# My Skill

## When to Activate
- Condition 1
- Condition 2

## Global Invariants
| Rule | Enforcement | Status |
|------|-------------|--------|
| Rule 1 | How enforced | MANDATORY |

## Contrastive Exemplars

✅ CORRECT:
```code
// Good pattern
```

❌ FAIL:
```code
// Bad pattern
```

## Anti-Patterns
| Pattern | Status | Reason |
|---------|--------|--------|
| Bad thing | FORBIDDEN | Why |
```

### 4. Configure Permissions

Edit `.claude/settings.local.json`:

```json
{
  "permissions": {
    "allow": ["commands you auto-approve"],
    "ask": ["commands requiring confirmation"],
    "deny": ["commands never allowed"]
  }
}
```

## Skill Sync

Keep skills updated from reference repositories:

```bash
# Check for updates
./scripts/skill-sync.sh

# Or manually
cd /path/to/reference-repo && git pull
# Then review .claude/skills/ in that repo for changes
```

### Reference Repositories

Add your reference repos to `scripts/skill-sync.sh`:

```bash
REFERENCE_REPOS=(
  "/path/to/repo1"
  "/path/to/repo2"
)
```

## Best Practices

### AGENTS.md (Passive Context)
Based on Vercel research: passive context in AGENTS.md outperforms active skill retrieval. Put critical instructions here.

### Skills (Domain Knowledge)
Use for detailed domain-specific patterns that agents load on-demand based on trigger keywords.

### Skill Structure
Follow the atomic skill pattern:
1. YAML frontmatter (name, description, triggers)
2. "When to Activate" section
3. Global Invariants table
4. Contrastive Exemplars (✅/❌)
5. Anti-Patterns section

### Contrastive Exemplars
Show both correct AND incorrect patterns. Research shows this is 8.4x more effective than negation-only ("NEVER do X").

### Recency Bias
Put the most critical constraints at the END of skills (in "Anti-Patterns" section). LLMs weight recent tokens more heavily.

## Included Skills

### code-quality.md
- YAGNI (You Aren't Gonna Need It)
- Minimal code philosophy
- No premature abstraction
- Delete, don't comment

### testing.md
- Test naming conventions
- Coverage requirements
- Mutation testing basics
- Security-critical coverage

### security.md
- Input validation
- No PII logging
- Dependency security
- HTTP security headers

## Customization Examples

### For Web3 Projects
Add skills:
- `polkadot-integration.md`
- `smart-contracts.md`
- `wallet-patterns.md`

### For Frontend Projects
Add skills:
- `design-system.md`
- `accessibility.md`
- `performance.md`

### For Backend Projects
Add skills:
- `api-design.md`
- `database-patterns.md`
- `error-handling.md`

## License

MIT
