---
name: skill-creator
description: Guide for creating Claude Code skills with latest frontmatter options. Use when creating new skills, updating existing skills, or extending Claude's capabilities with specialized knowledge, workflows, or tool integrations.
---

# Skill Creator

Create modular, self-contained skills that extend Claude's capabilities.

## Core Principles

### Concise is Key

Context window is shared with system prompt, conversation history, other skills, and user requests.

**Default assumption: Claude is already smart.** Only add context Claude doesn't have. Challenge each piece: "Does Claude really need this?" Prefer concise examples over verbose explanations.

### Degrees of Freedom

Match specificity to task fragility:

- **High freedom** (text instructions): Multiple approaches valid, context-dependent decisions
- **Medium freedom** (pseudocode/parameterized scripts): Preferred pattern exists, some variation acceptable
- **Low freedom** (specific scripts): Operations fragile, consistency critical, exact sequence required

Think of paths: narrow bridge needs guardrails (low freedom), open field allows many routes (high freedom).

### Progressive Disclosure

Three-level loading system:

1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<500 lines)
3. **Bundled resources** - As needed (unlimited)

## Skill Structure

```
skill-name/
├── SKILL.md          # Required: frontmatter + instructions
├── references/       # Optional: documentation loaded on demand
├── scripts/          # Optional: executable code
└── assets/           # Optional: templates, images, fonts
```

### SKILL.md (required)

- **Frontmatter** (YAML): `name` and `description` determine when skill triggers
- **Body** (Markdown): Instructions loaded AFTER triggering

### Bundled Resources (optional)

**scripts/**: Executable code for deterministic tasks or repeatedly rewritten code
- Example: `scripts/rotate_pdf.py` for PDF rotation

**references/**: Documentation loaded as needed into context
- Example: `references/schema.md` for database schemas
- For large files (>10k words), include grep patterns in SKILL.md
- Avoid duplication between SKILL.md and references

**assets/**: Files used in output, not loaded into context
- Example: `assets/template/` for boilerplate code

### What NOT to Include

Do NOT create extraneous files:
- README.md, INSTALLATION_GUIDE.md, CHANGELOG.md, etc.
- Skills are for AI agents, not user documentation

## Creation Workflow

1. **Understand** - Gather concrete usage examples from user
2. **Plan** - Identify reusable resources (scripts, references, assets)
3. **Create** - Make skill directory with SKILL.md
4. **Test** - Validate with real usage
5. **Iterate** - Improve based on actual performance
6. **Package** (optional) - Create .skill file for distribution

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
- `description`: Include WHAT it does + WHEN to use it (trigger terms). All "when to use" info goes here, not in body

### Body

Keep under 500 lines. Use imperative form.

- Core workflow in SKILL.md
- Detailed references in separate files

## Progressive Disclosure Patterns

### Pattern 1: High-level guide with references

```markdown
# PDF Processing

## Quick start
Extract text with pdfplumber:
[code example]

## Advanced features
- **Form filling**: See [FORMS.md](references/FORMS.md)
- **API reference**: See [REFERENCE.md](references/REFERENCE.md)
```

Claude loads references only when needed.

### Pattern 2: Domain-specific organization

For skills with multiple domains or frameworks:

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── references/
    ├── finance.md
    ├── sales.md
    └── product.md
```

User asks about sales → Claude only reads sales.md.

### Pattern 3: Conditional details

```markdown
# DOCX Processing

## Creating documents
Use docx-js for new documents.

## Editing documents
For simple edits, modify XML directly.

**For tracked changes**: See [REDLINING.md](references/REDLINING.md)
```

**Guidelines:**
- Avoid deeply nested references - keep one level deep from SKILL.md
- For files >100 lines, include table of contents

## Design Patterns

- **Multi-step processes**: See [workflows.md](references/workflows.md)
- **Output formats**: See [output-patterns.md](references/output-patterns.md)

## Packaging (Optional)

Create distributable .skill file when needed for sharing:

```bash
zip -r my-skill.skill my-skill/
```

Validate before packaging:
- Frontmatter has required fields
- Description includes trigger terms
- References link correctly
- Scripts execute without errors
