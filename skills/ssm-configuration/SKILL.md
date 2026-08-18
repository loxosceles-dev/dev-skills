---
name: ssm-runtime-configuration
description: How services consume runtime configuration from SSM Parameter Store. Apply when a Lambda or service needs to read configuration values at runtime.
type: pattern
---

# SSM Runtime Configuration

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Audience**: Service developers (Lambda, ECS, frontend). If you're using CDK to deploy infrastructure, see [CDK Bootstrap Configuration](../infrastructure/cdk-bootstrap-configuration.md).

**Problem**: Configuration scattered across .env files, CI/CD secrets, and cloud resources becomes out of sync and hard to manage.

**Solution**: Use AWS SSM Parameter Store as single source of truth for runtime configuration, with minimal .env files only for local development overrides.

---

## Pattern

**Architecture**:
```
Infrastructure Deployment → Creates/Updates SSM Parameters
                                      ↓
                            SSM Parameter Store
                            (Single Source of Truth)
                                      ↓
                    ┌─────────────────┴─────────────────┐
                    ↓                                   ↓
            Local Development                    CI/CD Pipeline
         (with .env.local overrides)          (SSM values only)
```

**Key Components**:
- **SSM Parameter Store**: Runtime configuration for all environments
- **infrastructure/.env**: Bootstrap config (AWS account, region) - deployment only
- **service/.env.local**: Local development overrides - optional, not committed

---

## Why This Pattern?

**Benefits**:
- **Single Source of Truth**: All runtime config in SSM, no sync issues
- **Environment Isolation**: Separate parameters per environment
- **No Secrets in Repo**: Sensitive values stay in AWS
- **CI/CD Compatible**: Pipelines fetch from SSM, no local files needed
- **Runtime Flexibility**: Change config without redeployment

**Use Cases**:
- AWS serverless applications
- Multi-environment deployments
- Projects with sensitive configuration
- CI/CD pipelines

---

## Implementation

**SSM Namespace Structure**:
```
/{project-id}/{environment}/{service}/VARIABLE_NAME

Examples:
/my-app/local/frontend/API_ENDPOINT
/my-app/dev/frontend/API_ENDPOINT
/my-app/prod/backend/DATABASE_URL
```

**Bootstrap Configuration** (infrastructure/.env):
```bash
# Minimal config for CDK deployment
CDK_DEFAULT_ACCOUNT=123456789012
CDK_DEFAULT_REGION=eu-central-1
```

**Local Overrides** (frontend/.env.local):
```bash
# Override SSM values for local development only
API_ENDPOINT=http://localhost:3000
```

**Retrieving Parameters**:
```typescript
// At application startup
import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';

const ssmClient = new SSMClient({ region: process.env.AWS_REGION });

async function getConfig(environment: string, service: string) {
  const path = `/${PROJECT_ID}/${environment}/${service}/`;
  // Fetch all parameters under path
  // Apply .env.local overrides if environment === 'local'
  return config;
}
```

---

## File Strategy

**What to Commit**:
- ✅ `infrastructure/.env` - Bootstrap config (no secrets)
- ✅ `.env_TEMPLATE` files - Documentation
- ❌ `.env.local` - Local overrides (gitignored)
- ❌ `.env.dev`, `.env.prod` - Runtime config (in SSM instead)

**Template Files**:
```bash
# .env_TEMPLATE
# Purpose: Document expected variables
# Instructions: Copy to .env.local and customize

# API Endpoint (from SSM by default)
# API_ENDPOINT=http://localhost:3000
```

---

## CLI Integration

```bash
# Get single parameter
ssm-params get /{project-id}/dev/frontend/API_ENDPOINT

# Export all parameters for service
ssm-params export-service dev frontend

# Output as .env format
ssm-params export-service dev frontend > .env
```

---

## Tradeoffs

**Pros**:
- Single source of truth
- No sync issues
- Secure secret storage

**Cons**:
- Requires AWS access for local development
- Slightly slower startup (network call to SSM)
- More complex than simple .env files

**When NOT to Use**:
- Non-AWS projects
- Simple applications with no sensitive config
- Projects without multiple environments

---

## Related Patterns

- **[CDK Bootstrap Configuration](../infrastructure/cdk-bootstrap-configuration.md)** - For CDK projects: how to write outputs to SSM without causing context caching issues
- [Environment Validation](../infrastructure/environment-validation.md) - Validate config early
- [Environment Deployment Strategy](../infrastructure/environment-deployment-strategy.md) - How environments are deployed
- [Security Baseline](../../CORE_PRINCIPLES.md#8-security-baseline) - Secret management principles

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
