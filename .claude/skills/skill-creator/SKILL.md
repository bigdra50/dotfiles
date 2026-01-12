---
name: skill-creator
description: Guide for creating Claude Code skills with latest frontmatter options. Use when creating new skills, updating existing skills, or extending Claude's capabilities with specialized knowledge, workflows, or tool integrations.
---

# Skill Creator

Create modular, self-contained skills that extend Claude's capabilities.

## Skill Structure

```
skill-name/
├── SKILL.md          # Required: frontmatter + instructions
├── references/       # Optional: documentation loaded on demand
├── scripts/          # Optional: executable code
└── assets/           # Optional: templates, images, fonts
```

## Creation Workflow

1. **Understand** - Gather concrete usage examples from user
2. **Plan** - Identify reusable resources (scripts, references, assets)
3. **Create** - Make skill directory with SKILL.md
4. **Test** - Validate with real usage
5. **Package** (optional) - Create .skill file for distribution

## Writing SKILL.md

### Frontmatter

Required and optional fields. See [frontmatter-reference.md](references/frontmatter-reference.md) for complete options.

```yaml
---
name: my-skill
description: What it does and when to use it. Include trigger terms.
# Optional fields below
allowed-tools: Read, Grep, Glob
model: claude-sonnet-4-20250514
context: fork
agent: Explore
user-invocable: true
---
```

**Key rules:**
- `name`: lowercase, hyphens, 64 chars max
- `description`: Include WHAT it does + WHEN to use it (trigger terms)
- Use imperative form in body text

### Body

Keep under 500 lines. Use progressive disclosure:
- Core workflow in SKILL.md
- Detailed references in separate files

## Resource Guidelines

### references/
Documentation loaded on demand. Link from SKILL.md:
```markdown
See [api-docs.md](references/api-docs.md) for API details.
```

### scripts/
Executable code for deterministic operations. Test before including.

### assets/
Templates, images, fonts used in output. Not loaded into context.

## Design Patterns

- **Multi-step processes**: See [workflows.md](references/workflows.md)
- **Output formats**: See [output-patterns.md](references/output-patterns.md)

## Packaging (Optional)

Create distributable .skill file only when needed for sharing:

```bash
zip -r my-skill.skill my-skill/
```

Validate before packaging:
- Frontmatter has required fields
- Description includes trigger terms
- References link correctly
- Scripts execute without errors
