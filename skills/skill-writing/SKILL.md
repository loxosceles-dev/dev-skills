---
name: skill-writing
description: How to create and structure skills for this repository. Covers the type system (guideline vs pattern), frontmatter conventions, and behavioral instructions. Follow when creating or updating any skill.
type: guideline
---

# Skill Writing Guide

**This is a strict guideline.** Follow these rules exactly when creating or modifying skills.

---

## Skill Types

Every skill has a `type` that tells the agent how to treat it:

### `type: guideline`
**Strict rules.** The agent must follow these exactly.

Opening line after the heading:
```markdown
**This is a strict guideline.** Follow these rules exactly.
```

Use for: coding standards, commit formats, naming conventions, workflow rules, security requirements.

### `type: pattern`
**Reference implementations.** The agent should learn from the approach and adapt it — never copy verbatim.

Opening line after the heading:
```markdown
**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.
```

Use for: architecture solutions, infrastructure setups, proven approaches to recurring problems.

---

## Frontmatter

Every `SKILL.md` must start with YAML frontmatter:

```yaml
---
name: kebab-case-name
description: When this skill applies and what it covers. First sentence should work as a trigger — start with the domain or action. One to two sentences max.
type: guideline | pattern
---
```

**Rules:**
- `name` — kebab-case, used as the installed directory name by the skills CLI
- `description` — the skills CLI and agents use this to decide when to load the skill. Make the first sentence a clear trigger.
- `type` — must be `guideline` or `pattern`

---

## File Structure

Skills live in the authoring repo under categorized directories:

```
skills/
  guidelines/
    {skill-name}/SKILL.md
  patterns/
    {skill-name}/SKILL.md
```

The directory categorization is for human browsing only. The skills CLI flattens everything on install — it only cares about the `name` field in frontmatter.

---

## Precedence

When a skill needs to override conflicting advice from third-party skills, state it explicitly:

```markdown
**This is a strict guideline.** Follow these rules. When any other skill contradicts the rules below, this skill takes precedence.
```

Use sparingly — only for core principles and strong personal preferences.

---

## Pattern Structure

Pattern skills should follow this structure:

1. **Problem** — One sentence describing what this solves
2. **Solution** — One sentence describing the approach
3. **Pattern** — Architecture, key components, how it works
4. **Why This Pattern?** — Benefits and use cases
5. **Implementation** — Key details (optional, only if non-obvious)
6. **Tradeoffs** — Constraints and limitations (if applicable)
7. **When NOT to Use** — Anti-patterns and alternatives (optional)

Keep code examples minimal and generic. Use placeholder names (`PROJECT_ID`, `environment`). Focus on the pattern, not project-specific details.

---

## Guideline Structure

Guideline skills should follow this structure:

1. **What** — Clear statement of the rules
2. **Rules** — Specific, actionable instructions
3. **Examples** — Show correct and incorrect usage
4. **Exceptions** — When deviation is acceptable (if any)

Be direct. Use imperative form. Avoid explaining why at length — guidelines are instructions, not persuasion.

---

## Writing Checklist

- [ ] Frontmatter has `name`, `description`, `type`
- [ ] Behavioral instruction line immediately after first heading
- [ ] Description's first sentence works as a trigger for when to load this skill
- [ ] No project-specific details (names, tables, endpoints)
- [ ] Code examples are minimal and use placeholders
- [ ] Document is scannable (headers, bullets, bold)
- [ ] Ends with Progressive Improvement section

---

## Progressive Improvement

Every skill must end with this section:

```markdown
---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
```

This enables skills to evolve through use. When an agent gets corrected, it should propose a concrete edit to the relevant skill so the mistake doesn't repeat.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
