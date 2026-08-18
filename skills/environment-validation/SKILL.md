---
name: environment-validation
description: Validate configuration early to fail fast. Apply when writing setup scripts, Lambda cold starts, or any initialization code that depends on environment variables.
type: pattern
---

# Environment Validation Pattern

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Problem**: Scripts fail halfway through due to missing environment variables, wasting time and leaving systems in inconsistent states.

**Solution**: Validate all required environment variables at the start, before any operations begin.

---

## Pattern

**Validate Early**: Check all required configuration before starting business logic.

```typescript
// ✅ Preferred: Validate at entry point
function validateEnvironment() {
  const required = ['AWS_REGION', 'PROJECT_ID', 'ENVIRONMENT'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
}

// At script/app entry point
validateEnvironment();
// Now proceed with business logic
```

**Environment Manager Pattern** (for complex projects):

```typescript
// shared/env-loader.ts
export function loadAndValidateEnv() {
  const required = ['AWS_REGION', 'PROJECT_ID', 'ENVIRONMENT'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(`Missing: ${missing.join(', ')}`);
  }
  
  return {
    awsRegion: process.env.AWS_REGION!,
    projectId: process.env.PROJECT_ID!,
    environment: process.env.ENVIRONMENT!
  };
}

// Usage in scripts/handlers
const config = loadAndValidateEnv();
// All env vars validated, proceed with business logic
```

---

## Benefits

- **Fail Fast**: Catch configuration errors immediately
- **Clear Errors**: Know exactly what's missing
- **Clean Code**: Business logic not cluttered with validation
- **Consistent**: Single validation point for entire application

---

## When to Use

- **Always**: For deployment scripts, Lambda handlers, CLI tools
- **Entry Points**: Validate at application/script start
- **Shared Config**: Use environment manager for complex projects

---

## Integration with CLI Architecture

The [3-Tier CLI Architecture](cli-architecture-pattern.md#3-tier-architecture-for-complex-projects) includes an `EnvironmentManager` that implements this pattern:

```typescript
// core/env-manager.ts
export class EnvironmentManager extends BaseManager {
  loadEnv(stage: string): Record<string, string> {
    this.log(`Loading environment for ${stage}`);
    
    // Validate required variables
    const required = ['AWS_REGION', 'PROJECT_ID'];
    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      throw new Error(`Missing: ${missing.join(', ')}`);
    }
    
    return process.env;
  }
}
```

This ensures all CLI commands validate environment before executing business logic.

---

## Related

- [CLI Architecture](cli-architecture-pattern.md) - 3-Tier pattern includes EnvironmentManager
- [Configuration Management](../../CORE_PRINCIPLES.md#7-configuration-management)
- [Error Handling](../../CORE_PRINCIPLES.md#8-error-handling)
- [Security Baseline](../../CORE_PRINCIPLES.md#9-security-baseline)

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
