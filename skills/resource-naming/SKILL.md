---
name: resource-naming
description: AWS resource naming conventions with environment separation. Pattern {project-id}-{resource}-{environment}. Apply when creating any AWS resource — Lambda, DynamoDB, S3, etc.
type: pattern
---

# AWS Resource Naming Conventions

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Status**: 🔴 CRITICAL PATTERN  
**Category**: Infrastructure  
**Applies To**: All AWS resources across all projects

---

## Overview

This document defines the standard naming conventions for AWS resources. Following these patterns ensures:
- Clear project ownership
- Environment separation and safety
- Consistent resource identification
- Easy filtering and management in AWS Console
- Prevention of resource conflicts and data corruption

---

## Standard Naming Pattern

### Core Format
```
{project}-{resource-name}-{environment}
```

### Components

1. **Project Prefix** (required)
   - Short identifier for the project (2-4 characters)
   - Lowercase letters only
   - Examples: `cme`, `aip`, `app`
   - Identifies which project owns the resource

2. **Resource Name** (required)
   - Describes the resource's purpose
   - Lowercase with hyphens
   - Examples: `job-extractor`, `opportunities`, `website`

3. **Environment Suffix** (required)
   - `dev` - Development environment
   - `prod` - Production environment
   - `staging` - Staging environment (optional)
   - `local` - Local development (for configuration only, never deployed)
   - Always in last position for consistency

### Why This Pattern?

- ✅ **Project ownership clear**: Prefix identifies the owning project
- ✅ **Consistent environment position**: Always at the end
- ✅ **Short names**: No account/region unless required for uniqueness
- ✅ **AWS best practice**: Lowercase with hyphens
- ✅ **Easy filtering**: Can filter by prefix in AWS Console
- ✅ **Multi-project support**: Clear separation when multiple projects share an account
- ✅ **Prevents conflicts**: Environment suffix prevents dev/prod overwrites

---

## Account Strategy: Single vs. Multi-Account

### Two Deployment Approaches

**Option 1: Single Account** (dev and prod in same AWS account)
- Lower cost (no cross-account complexity)
- Simpler IAM and networking
- **Requires** environment suffix to prevent conflicts

**Option 2: Multi-Account** (separate AWS accounts for dev and prod)
- Better isolation and security
- Separate billing and cost tracking
- **Still requires** environment suffix for safety

### Why Environment Suffix is Always Required

**Even with separate AWS accounts**, the environment suffix provides critical safety:

1. **Human Error Prevention**: Immediately see which environment you're working in
   ```bash
   # Without environment suffix
   aws lambda list-functions
   → job-extractor  # Which environment is this?
   
   # With environment suffix
   aws lambda list-functions
   → job-extractor-prod  # Clear: this is production!
   ```

2. **Account Confusion Protection**: Prevents mistakes when switching between accounts
   ```bash
   # You think you're in dev account, but you're actually in prod
   # Without suffix: You might delete "job-extractor" thinking it's dev
   # With suffix: You see "job-extractor-prod" and stop immediately
   ```

3. **Future-Proofing**: Account strategy might change
   - Start with single account, later split to multi-account
   - Merge accounts for cost optimization
   - Add staging environment to existing account

4. **Consistency**: Same naming pattern works everywhere
   - Local development
   - CI/CD pipelines
   - AWS Console
   - CloudFormation/CDK code

### Real-World Scenario

```bash
# You're debugging an issue and need to check Lambda logs
# You have AWS CLI configured with multiple profiles

# Scenario 1: Without environment suffix
aws lambda get-function --function-name job-extractor --profile prod-account
# ⚠️  Is this the right function? Hard to tell from name alone

# Scenario 2: With environment suffix
aws lambda get-function --function-name job-extractor-prod --profile prod-account
# ✅ Name confirms you're looking at production resource
# ✅ Immediate visual confirmation prevents mistakes
```

**Rule**: Always include environment suffix, regardless of account strategy. It's a safety layer that costs nothing but prevents costly mistakes.

---

## Critical: Why Environment Suffix Matters

### The Problem

Without environment identifiers in resource names, dev and prod resources conflict when deployed to the same AWS account, causing overwrites and data corruption.

### Real-World Impact

**Lambda Functions** (no environment in name):
```typescript
// ❌ WRONG
functionName: 'job-data-extractor'

// GitHub Actions deploys dev
ENVIRONMENT=dev → Lambda: job-data-extractor

// GitHub Actions deploys prod
ENVIRONMENT=prod → Lambda: job-data-extractor  // OVERWRITES dev!
```

**DynamoDB Tables** (no environment in name):
```typescript
// ❌ WRONG
tableName: `opportunities-${account}-${region}`

// Both environments use SAME table
// Result: Dev and prod data MIXED!
```

### The Solution

**Always include environment in resource names**:
```typescript
// ✅ CORRECT
functionName: `job-data-extractor-${environment}`
tableName: `opportunities-${environment}`

// Results:
// dev:  job-data-extractor-dev, opportunities-dev
// prod: job-data-extractor-prod, opportunities-prod
```

---

## Resource-Specific Patterns

### Lambda Functions
**Pattern**: `{project}-{function-name}-{environment}`

**Examples**:
```typescript
// ✅ CORRECT
functionName: `cme-job-extractor-${environment}`
functionName: `aip-data-sync-${environment}`

// Results:
// cme-job-extractor-dev
// cme-job-extractor-prod
// aip-data-sync-dev
```

**Rationale**: Lambda names must be unique per account. Environment suffix prevents dev/prod conflicts.

---

### DynamoDB Tables
**Pattern**: `{project}-{table-name}-{environment}`

**Examples**:
```typescript
// ✅ CORRECT
tableName: `cme-opportunities-${environment}`
tableName: `aip-user-sessions-${environment}`

// Results:
// cme-opportunities-dev
// cme-opportunities-prod
```

**Optional Extended Pattern** (when uniqueness needed):
```typescript
tableName: `{project}-{table-name}-${environment}-${account}-${region}`

// Example:
// cme-opportunities-dev-123456-us-east-1
```

**Rationale**: Table names must be unique per account. Environment suffix is critical to prevent data mixing.

---

### S3 Buckets
**Pattern**: `{project}-{bucket-purpose}-{environment}` (add random suffix if collision)

**Examples**:
```typescript
// ✅ CORRECT
bucketName: `cme-website-${environment}`
bucketName: `aip-assets-${environment}`

// Results:
// cme-website-dev
// cme-website-prod
```

**If collision occurs** (bucket name already taken globally):
```typescript
bucketName: `cme-website-${environment}-x7k2m`

// Results:
// cme-website-dev-x7k2m
// cme-website-prod-p9n4q
```

**Important Notes**:
- Bucket names must be **globally unique** across ALL AWS accounts
- Use lowercase letters, numbers, and hyphens only (no underscores)
- If deployment fails with "BucketAlreadyExists", add random suffix
- Suffix format: 5 random lowercase alphanumeric characters

**Rationale**: Bucket names must be globally unique. Start with clean pattern, add suffix only if needed.

---

### API Gateway
**Pattern**: `{PROJECT} API - {environment}` (display name, uppercase project)

**Examples**:
```typescript
// ✅ CORRECT
restApiName: `CME API - ${environment}`
restApiName: `AIP API - ${environment}`

// Results:
// CME API - dev
// CME API - prod
```

**Rationale**: Display name for humans. Uppercase for readability in AWS Console.

---

### CloudFront Distributions
**Pattern**: Comment field: `{Project Name} - {environment}`

**Examples**:
```
Career Match Engine - dev
AI Portfolio - prod
```

**Tag**: `Environment: dev` or `Environment: prod`

**Rationale**: CloudFront IDs are auto-generated. Use comment and tags for identification.

---

### Lambda Layers
**Pattern**: `{project}-{layer-name}` or `{project}-{layer-name}-{environment}`

**Examples**:
```typescript
// Shared across environments
layerName: 'cme-common-layer'
layerName: 'aip-utils-layer'

// Environment-specific
layerName: `cme-config-layer-${environment}`
```

**Note**: Layers are often shared across environments. Environment suffix optional.

**Rationale**: Layers are versioned. Sharing across environments reduces duplication.

#### Lambda Layer Code Organization

**Goal**: Provide each Lambda with only what it needs while avoiding code duplication. This is a trade-off between deployment size and code reuse - evaluate on a case-by-case basis.

**Layer Structure**: Organize by scope and reusability

```
layers/
  common/                # Truly shared utilities (3+ consumers)
    nodejs/
      logger.mjs
      response-builder.mjs
      config-loader.mjs
      validation.mjs
  
  feature-utils/         # Feature-specific utilities
    nodejs/
      feature-operations.mjs
      feature-schemas.mjs
  
  external-sdks/         # Third-party integrations
    nodejs/
      package.json       # npm dependencies
      sdk-wrapper.mjs
```

**Organizing Shared Code**:

**Common Layer** - For widely-used utilities:
- Generic helpers (logging, validation, response formatting)
- Used by 3+ different features
- No feature-specific logic

**Feature Layer** - For feature-specific shared code:
- Operations and schemas for a specific domain
- Used by 2+ functions within that feature
- Contains feature-specific logic

**Integration Layer** - For external dependencies:
- Third-party SDK packages
- Wrappers around external services
- Isolates version management

**Using Multiple Layers**:
```typescript
// Function can reference multiple layers
const myFunction = new Function({
  layers: [
    commonLayer,        // Generic utilities
    featureALayer,      // Feature A utilities
    featureBLayer       // Feature B utilities (if needed)
  ]
});
```

**Decision Guide**:
- **Generic utilities** → `common` layer
- **Feature-specific code** → feature layer
- **External packages** → integration layer
- **Cross-feature needs** → Reference multiple layers

**Trade-offs**:
- More layers = lighter individual Lambdas but more complexity
- Fewer layers = simpler setup but larger deployments
- Balance based on your project's needs

**Example Scenario**: API schemas used by multiple features
- **If generic**: Move to `common` layer
- **If feature-specific**: Keep in feature layer, other features reference it
- **Don't duplicate**: Use layer composition

---

### SQS Queues
**Pattern**: `{project}-{queue-name}-{environment}`

**Examples**:
```typescript
queueName: `cme-job-processing-${environment}`
queueName: `aip-notifications-${environment}`
```

---

### SNS Topics
**Pattern**: `{project}-{topic-name}-{environment}`

**Examples**:
```typescript
topicName: `cme-alerts-${environment}`
topicName: `aip-events-${environment}`
```

---

### EventBridge Rules
**Pattern**: `{project}-{rule-name}-{environment}`

**Examples**:
```typescript
ruleName: `cme-daily-sync-${environment}`
ruleName: `aip-cleanup-${environment}`
```

---

### Step Functions
**Pattern**: `{project}-{state-machine-name}-{environment}`

**Examples**:
```typescript
stateMachineName: `cme-workflow-${environment}`
stateMachineName: `aip-pipeline-${environment}`
```

---

### Secrets Manager
**Pattern**: `{project}/{environment}/{secret-name}`

**Examples**:
```typescript
secretName: `cme/${environment}/api-key`
secretName: `aip/${environment}/db-password`
```

---

### SSM Parameters
**Pattern**: `/{project}/{environment}/{namespace}/{key}`

**Examples**:
```
/cme/dev/lambda/job-extractor/LLM_API_KEY
/cme/prod/api/corsAllowedOrigins
/aip/dev/frontend/api-endpoint
```

**Note**: Use camelCase for project name in SSM for historical compatibility.

---

### CloudWatch Log Groups
**Pattern**: `/aws/lambda/{project}-{function-name}-{environment}`

**Examples**:
```
/aws/lambda/cme-job-extractor-dev
/aws/lambda/cme-recruiter-chat-prod
/aws/lambda/aip-data-sync-dev
```

**Note**: Auto-generated by Lambda. Follows Lambda naming automatically.

---

## CDK Implementation Pattern

### Construct Props

```typescript
export interface ResourceConstructProps {
  projectPrefix: string;    // 'cme', 'aip', etc.
  environment: string;      // 'dev', 'prod', 'staging'
  account: string;
  region: string;
}
```

### Lambda Function

```typescript
const myFunction = new lambda.Function(this, 'MyFunction', {
  functionName: `${props.projectPrefix}-my-function-${props.environment}`,
  runtime: lambda.Runtime.NODEJS_22_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('lambda'),
  environment: {
    ENVIRONMENT: props.environment,
    PROJECT: props.projectPrefix
  }
});
```

### DynamoDB Table

```typescript
const myTable = new dynamodb.Table(this, 'MyTable', {
  tableName: `${props.projectPrefix}-my-table-${props.environment}`,
  partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
  removalPolicy: props.environment === 'prod' 
    ? cdk.RemovalPolicy.RETAIN 
    : cdk.RemovalPolicy.DESTROY
});
```

### S3 Bucket

```typescript
const myBucket = new s3.Bucket(this, 'MyBucket', {
  bucketName: `${props.projectPrefix}-my-bucket-${props.environment}`,
  removalPolicy: props.environment === 'prod'
    ? cdk.RemovalPolicy.RETAIN
    : cdk.RemovalPolicy.DESTROY,
  autoDeleteObjects: props.environment !== 'prod'
});
```

---

## Environment Variable Setup

### Required Environment Variable

```bash
# Must be set before deployment
export ENVIRONMENT=dev  # or 'prod', 'staging', etc.
export PROJECT_PREFIX=myapp  # Short project identifier
```

### Deployment Script

```bash
#!/bin/bash
set -e

if [ -z "$ENVIRONMENT" ]; then
  echo "Error: ENVIRONMENT is not set"
  echo "Usage: ENVIRONMENT=dev ./deploy.sh"
  exit 1
fi

if [ -z "$PROJECT_PREFIX" ]; then
  echo "Error: PROJECT_PREFIX is not set"
  echo "Usage: PROJECT_PREFIX=myapp ENVIRONMENT=dev ./deploy.sh"
  exit 1
fi

echo "Deploying $PROJECT_PREFIX to environment: $ENVIRONMENT"
cdk deploy --all
```

### GitHub Actions

```yaml
name: Deploy

on:
  push:
    branches:
      - main      # Deploys to prod
      - develop   # Deploys to dev

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set environment
        run: |
          if [ "${{ github.ref }}" == "refs/heads/main" ]; then
            echo "ENVIRONMENT=prod" >> $GITHUB_ENV
          else
            echo "ENVIRONMENT=dev" >> $GITHUB_ENV
          fi
          echo "PROJECT_PREFIX=myapp" >> $GITHUB_ENV
      
      - name: Deploy
        run: |
          echo "Deploying $PROJECT_PREFIX to $ENVIRONMENT"
          ./deploy.sh
```

---

## Validation Checklist

Before deploying any resource, verify:

- [ ] Starts with project prefix (`cme-`, `aip-`, etc.)
- [ ] Ends with environment (`-dev`, `-prod`, `-staging`)
- [ ] Uses lowercase with hyphens (except API Gateway display names)
- [ ] No hardcoded environment values (use variables)
- [ ] Name clearly describes resource purpose
- [ ] Follows pattern: `{project}-{resource-name}-{environment}`
- [ ] Environment variable is set before deployment

---

## Common Pitfalls

### ❌ Pitfall 1: Hardcoded Environment

```typescript
// ❌ WRONG - Hardcoded 'dev'
bucketName: `my-app-dev`

// ✅ CORRECT - Use variable
bucketName: `my-app-${environment}`
```

### ❌ Pitfall 2: Missing Environment Variable

```typescript
// ❌ WRONG - No environment
functionName: 'my-function'

// ✅ CORRECT - Include environment
functionName: `my-function-${environment}`
```

### ❌ Pitfall 3: Inconsistent Pattern

```typescript
// ❌ WRONG - Inconsistent
functionName: `my-function-${environment}`  // Has environment
tableName: `my-table`  // Missing environment

// ✅ CORRECT - Consistent
functionName: `my-function-${environment}`
tableName: `my-table-${environment}`
```

### ❌ Pitfall 4: Missing Project Prefix

```typescript
// ❌ WRONG - No project identification
functionName: `job-extractor-${environment}`

// ✅ CORRECT - Include project prefix
functionName: `cme-job-extractor-${environment}`
```

### ❌ Pitfall 5: Assuming Different Accounts Mean No Environment Suffix Needed

```typescript
// ❌ WRONG ASSUMPTION
// "We use different AWS accounts for dev/prod, so we don't need environment in names"
functionName: 'job-extractor'  // No environment suffix

// ✅ CORRECT - Always include environment
functionName: `job-extractor-${environment}`

// REALITY:
// - Human error: You might be in wrong account without realizing
// - Visual confirmation: Name tells you it's prod even if you're confused about account
// - Account strategy might change (single → multi or multi → single)
// - Consistency: Same pattern works for single and multi-account setups
// - Safety layer: Costs nothing, prevents costly mistakes
```

---

## Migration from Old Names

### Audit Phase
1. List all AWS resources in the account
2. Identify resources without environment in name
3. Identify resources without project prefix
4. Document which environments are affected
5. Plan migration strategy

### Migration Phase
1. Deploy new resources with correct names
2. Migrate data from old to new resources
3. Update application to use new resources
4. Verify new resources working
5. Delete old resources after validation

---

## Validation

### How to Verify Separation

**AWS Console Check**:
```bash
# List all Lambda functions
aws lambda list-functions --query 'Functions[*].FunctionName'

# Should see:
# - cme-my-function-dev
# - cme-my-function-prod
# ✅ Clear project and environment separation

# NOT:
# - my-function
# ❌ No project or environment identifier
```

**DynamoDB Check**:
```bash
# List all tables
aws dynamodb list-tables

# Should see:
# - cme-my-table-dev
# - cme-my-table-prod
# ✅ Clear separation
```

**Deployment Test**:
```bash
# Deploy dev
ENVIRONMENT=dev ./deploy.sh

# Deploy prod
ENVIRONMENT=prod ./deploy.sh

# Verify:
# - No resource overwrites
# - Both environments coexist
# - No conflicts or errors
```

---

## Quick Reference

### ✅ DO

- Include project prefix in ALL resource names
- Include `${environment}` in ALL resource names
- Use consistent naming pattern across all resources
- Validate environment variable is set before deployment
- Test both dev and prod deployments to same account
- Document naming convention in project README

### ❌ DON'T

- Hardcode environment values ('dev', 'prod')
- Skip project prefix in resource names
- Assume different AWS accounts mean no naming needed
- Skip environment in "temporary" or "test" resources
- Use different naming patterns for different resource types
- Deploy without verifying environment variable

---

## Related Patterns

- [Configuration Management](../configuration/management.md) - Environment-specific configuration
- [Infrastructure Overview](./overview.md) - General infrastructure patterns
- [Security Overview](../security/overview.md) - Security considerations

---

## Summary

**Critical Rules**:
1. Every AWS resource name MUST include the project prefix
2. Every AWS resource name MUST include the environment identifier
3. Use the pattern: `{project}-{resource-name}-{environment}`

**Why**: 
- Prevents resource conflicts and data corruption
- Enables clear project ownership
- Allows safe multi-environment deployments to same account
- Facilitates easy resource identification and management

**How**: Use `${projectPrefix}` and `${environment}` variables in all resource names consistently.

**Validation**: Deploy both dev and prod to same account and verify no conflicts.

**Remember**: This is not optional. It's a critical pattern that prevents production incidents and enables clear resource management.

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
