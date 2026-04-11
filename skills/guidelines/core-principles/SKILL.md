---
name: core-principles
description: Universal coding principles that apply to all projects. These preferences take precedence over conflicting advice from third-party skills. Follow when writing or reviewing any code.
type: guideline
---

# Core Principles

**This is a strict guideline.** Follow these rules. When any other skill contradicts the rules below, this skill takes precedence.

Essential guidelines that apply to ALL projects.

**Important**: These are guiding principles, not absolute rules. Project context matters. If you need to deviate, explain your reasoning and trade-offs.

**Note on Examples**: Code examples may use specific languages (JavaScript, Python, etc.) for clarity, but principles apply universally. Adapt patterns to your project's language and context.

---

## 1. Prefer Pure Functions

Helper functions should accept data as parameters rather than reading from globals or environment.

```typescript
// ✅ Preferred: Pure, testable, moveable
function buildResourceName(environment: string, type: string, name: string): string {
  return `${environment}-${type}-${name}`;
}

// ⚠️ Less ideal: Reads from global
const ENV = process.env.ENVIRONMENT;
function buildResourceName(type: string, name: string): string {
  return `${ENV}-${type}-${name}`;
}
```

**When impurity is necessary** (AWS calls, DB access): Keep scope minimal, pass clients as parameters when feasible.

## 2. No Silent Defaults — Fail Fast, Fail Loud

Almost never use fallback values. Missing configuration, missing data fields, and unexpected states should cause immediate, loud failures with meaningful error messages.

```javascript
// ❌ Silent fallback — masks misconfiguration
const region = process.env.AWS_REGION || 'us-east-1';

// ✅ Fail fast with actionable error
if (!process.env.AWS_REGION) {
  throw new Error('AWS_REGION is required. Set in environment or SSM.');
}
const region = process.env.AWS_REGION;
```

```python
# ❌ Silent default — hides corrupt data
source = status.get("scrape_source", "")

# ✅ Required field — let it fail if missing
source = status["scrape_source"]
```

**The one exception — user-facing resilience**: API endpoints and frontend code must not crash entirely because of a single bad record or missing non-essential field. In these cases:
- Catch the error at the **loop/item level** (not the field level)
- **Log the full error** with identifying context (pk, sk, etc.)
- **Skip the bad record**, serve the rest
- Never scatter `.get("field", "")` defaults across every field — that silently hides data bugs

```python
# ✅ Correct: required fields fail loud, but one bad record doesn't crash the endpoint
for item in items:
    try:
        result.append(format_item(item))  # format_item uses item["field"] — no defaults
    except (KeyError, ValueError):
        logging.exception("Skipping corrupt item: pk=%s sk=%s", item.get("pk"), item.get("sk"))
```

**When in doubt** whether something is "non-essential": stop and discuss. The default stance is fail loud.

## 3. Code Structure and Organization

Aim for consistent file structure and clear separation of concerns.

**Recommended File Structure**:
1. Imports
2. Environment variable validation (fail fast on cold start)
3. Constants
4. AWS clients and expensive initializations
5. Types/Interfaces
6. Pure helper functions
7. Impure functions (AWS calls, I/O)
8. Entry point (handler, main, etc.)

**Separation of Concerns**:
- Prefer separate files for schemas, prompts, and business logic
- Avoid mixing unrelated functionality
- Balance between separation and over-fragmentation

**Function Declaration**:
- **Simple/inline**: Arrow functions `const fn = () => {}`
- **Complex logic**: Function keyword `function fn() {}`

## 4. Project Identifiers in Configuration

Avoid hardcoding project identifiers. Use configuration instead.

```typescript
// ❌ Avoid
const paramPath = `/myapp/${environment}/api-key`;

// ✅ Preferred
const PROJECT_ID = process.env.PROJECT_ID;
const paramPath = `/${PROJECT_ID}/${environment}/api-key`;
```

## 5. Error Handling

The default is to fail fast and loud. Graceful degradation is the rare exception, not the norm.

- **Throw/crash**: Missing configuration, missing required data fields, invalid setup, critical dependencies. This is the default.
- **Log + skip item**: Only at user-facing boundaries (API responses, frontend rendering) where one bad item must not take down the whole response. Catch at the item level, log with context, skip the item.
- **Never**: Scatter silent defaults (`.get("field", "")`) to avoid errors. That hides bugs.
- **Always**: Include actionable context in errors — what record, what field, what was expected.

## 6. Variable Naming

Use meaningful variable names. Avoid single-letter names except in well-established conventions.

```typescript
// ❌ Avoid
arr.map((a) => a.id);
catch (e) { console.error(e); }

// ✅ Preferred
users.map((user) => user.id);
catch (err) { console.error(err); }
```

**Acceptable abbreviations**: `err`, `evt`, `req`, `res`, `ctx`, `idx`, `fn`

**Exceptions**: Math formulas (`x`, `y`, `i`, `j`), trivial arrow functions (`[1,2,3].map(n => n * 2)`)

## 7. Security Baseline

- Keep secrets, API keys, and credentials out of repositories
- Use AWS Secrets Manager or SSM Parameter Store (SecureString)
- Fetch secrets at runtime, not build time
- Prefer IAM roles over hardcoded credentials
- Separate resources and secrets per environment

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
