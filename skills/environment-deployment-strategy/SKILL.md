---
name: environment-deployment-strategy
description: Safe deployment practices across local/dev/prod environments. Apply when setting up deployment pipelines or adding deployment scripts.
type: pattern
---

# Environment Deployment Strategy

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Problem**: Need safe deployment practices that prevent accidental production deployments while enabling rapid development iteration.

**Solution**: Three-tier environment strategy with deployment restrictions.

---

## Pattern

**Three Environments**:

1. **Local** (`local`)
   - Runs on developer machine
   - Uses cloud resources from `dev` environment
   - Cannot be deployed (no cloud resources)
   - Fast iteration, no deployment wait

2. **Development** (`dev`)
   - Deployed to cloud
   - Mirrors production architecture
   - Can deploy via: Local script OR GitHub Actions (on merge to `dev` branch)
   - Used for testing and validation

3. **Production** (`prod`)
   - Deployed to cloud
   - Live customer-facing environment
   - Can ONLY deploy via: GitHub Actions (on merge to `main` branch)
   - Never deployed from local machine

---

## Why This Pattern?

**Benefits**:
- **Safety**: Production protected from accidental local deployments
- **Speed**: Local development uses cloud dev resources (no local infrastructure)
- **Consistency**: Dev mirrors prod, catches issues before production
- **Audit Trail**: All prod deployments tracked in GitHub Actions logs
- **Rollback**: Git history enables easy rollback

**Prevents**:
- Accidental production deployments from developer machines
- Untested code reaching production
- Configuration drift between environments
- "Works on my machine" issues

---

## Implementation

**Environment Configuration**:

```bash
# .env (local - not committed)
ENVIRONMENT=local
AWS_REGION=eu-central-1
# Uses dev resources
API_ENDPOINT=https://api-dev.example.com

# .env.dev (committed template)
ENVIRONMENT=dev
AWS_REGION=eu-central-1
API_ENDPOINT=https://api-dev.example.com

# .env.prod (committed template, secrets from SSM)
ENVIRONMENT=prod
AWS_REGION=eu-central-1
API_ENDPOINT=https://api.example.com
```

**Deployment Scripts**:

```json
// package.json
{
  "scripts": {
    "deploy:dev": "cdk deploy --all --context environment=dev",
    "deploy:prod": "echo 'ERROR: Production can only be deployed via GitHub Actions' && exit 1"
  }
}
```

**GitHub Actions Workflow**:

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  pull_request:
    types: [closed]
    branches: [dev, main]

jobs:
  deploy-dev:
    if: github.base_ref == 'dev' && github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Dev
        run: npm run deploy:dev

  deploy-prod:
    if: github.base_ref == 'main' && github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Deploy to Production
        run: cdk deploy --all --context environment=prod
```

---

## Deployment Flow

**Development Cycle**:
```
1. Developer works locally (uses dev resources)
2. Commits to feature branch
3. Opens PR to dev branch
4. PR merged → GitHub Actions deploys to dev
5. Test in dev environment
6. Open PR from dev to main
7. PR merged → GitHub Actions deploys to prod
```

**Local Development**:
```bash
# Developer runs frontend locally
npm run dev

# Frontend connects to dev API
# No infrastructure deployment needed
# Fast iteration
```

**Dev Deployment** (two options):
```bash
# Option 1: Local deployment (for quick testing)
npm run deploy:dev

# Option 2: GitHub Actions (on PR merge to dev)
# Automatic, tracked, consistent
```

**Prod Deployment** (one option only):
```bash
# Only via GitHub Actions (on PR merge to main)
# Attempting local deployment fails with error message
```

---

## Resource Isolation

**Separate Resources Per Environment**:

```typescript
// All resources include environment identifier
const bucket = new s3.Bucket(this, 'Bucket', {
  bucketName: `${PROJECT_ID}-data-${environment}` // dev or prod
});

const table = new dynamodb.Table(this, 'Table', {
  tableName: `${PROJECT_ID}-users-${environment}` // dev or prod
});
```

**Why**: Prevents dev and prod from sharing resources, avoiding data corruption and conflicts.

---

## AWS CodePipeline Integration

**Alternative**: Use AWS CodePipeline instead of GitHub Actions

```typescript
// Separate pipelines per environment
const devPipeline = new codepipeline.Pipeline(this, 'DevPipeline', {
  pipelineName: `${PROJECT_ID}-pipeline-dev`
});

const prodPipeline = new codepipeline.Pipeline(this, 'ProdPipeline', {
  pipelineName: `${PROJECT_ID}-pipeline-prod`
});
```

**GitHub Actions trigger**:
```yaml
- name: Trigger Dev Pipeline
  run: aws codepipeline start-pipeline-execution --name ${PROJECT_ID}-pipeline-dev

- name: Trigger Prod Pipeline
  run: aws codepipeline start-pipeline-execution --name ${PROJECT_ID}-pipeline-prod
```

**Benefits**: 
- Build logs in AWS CloudWatch
- IAM-based permissions (no GitHub secrets)
- Integrated with AWS services

---

## Variations

**Two-Environment** (simpler projects):
- `dev` - Development and testing
- `prod` - Production only

**Four-Environment** (enterprise):
- `local` - Developer machines
- `dev` - Development
- `staging` - Pre-production testing
- `prod` - Production

---

## Related Patterns

- [Resource Naming](resource-naming.md) - How to name resources per environment
- [Environment Validation](environment-validation.md) - Validate environment config early
- [Static Frontend Hosting](static-frontend-hosting.md) - Deployment pipeline example

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
