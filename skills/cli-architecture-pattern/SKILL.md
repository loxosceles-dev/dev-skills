---
name: cli-architecture-pattern
description: Structured CLI architecture using 2-tier or 3-tier patterns with defined entrypoints, manager classes, and reusable commands. Apply when creating CLI tools, scripts, or any command-line interface instead of ad-hoc scripts.
type: pattern
---

# CLI Architecture Pattern

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Problem**: Infrastructure operations scattered across shell scripts, manual commands, and deployment pipelines become hard to maintain and inconsistent.

**Solution**: Structured CLI tools with uniform entry points.

---

## Why This Pattern?

**Benefits**:
- **Consistency**: Same commands work locally, in CI/CD, and deployment scripts
- **Readability**: `pnpm deploy:dev` is clearer than raw AWS CLI commands
- **Testability**: CLI commands can be tested independently
- **Reusability**: Share logic across different entry points
- **Documentation**: Commands are self-documenting with `--help`

**Integration Points**:
- Root `package.json` scripts (JS/TS projects)
- `pyproject.toml` scripts (Python projects)
- GitHub Actions workflows
- Deployment scripts (bash, etc.)
- Local development

**Example Integration**:
```json
// package.json
{
  "scripts": {
    "deploy:dev": "ts-node cli/bin/deploy.ts --env=dev",
    "export-params:dev": "ts-node cli/bin/ssm-params.ts export dev frontend"
  }
}
```

```yaml
# GitHub Actions
- name: Deploy infrastructure
  run: pnpm deploy:dev

- name: Export parameters
  run: pnpm export-params:dev
```

---

## 1-Tier Architecture (For Simple Projects)

**Structure**:
```
lib/
  infra.ts               # Single entry point: arg parsing + business logic
  core/
    environment-manager.ts  # Bootstrap config loader (shared utility)
```

**Single File** - All commands in one switch:
```typescript
// lib/infra.ts
import { EnvironmentManager } from './core/environment-manager';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { CloudFormationClient, DescribeStacksCommand } from '@aws-sdk/client-cloudformation';
import { CloudFrontClient, CreateInvalidationCommand } from '@aws-sdk/client-cloudfront';
import { spawn } from 'child_process';

const [command] = process.argv.slice(2);

async function main() {
  switch (command) {
    case 'deploy':
      await deploy();
      break;
    case 'publish':
      await publish();
      break;
    case 'synth':
      await run('npx', ['cdk', 'synth']);
      break;
    default:
      console.log('Commands: deploy | publish | synth');
      process.exit(1);
  }
}

async function deploy() {
  console.log('📦 Provisioning infrastructure...');
  await run('npx', ['cdk', 'deploy', '--all', '--require-approval', 'never']);
  console.log('🏗️ Publishing frontend...');
  await publish();
}

async function publish() {
  const stage = getStage();
  const stackName = `myproject-web-${stage}`;
  const region = new EnvironmentManager(stage).load().cdkDefaultRegion;

  await run('pnpm', ['--filter', 'frontend', 'run', 'build']);

  const bucketName = await getStackOutput(stackName, 'WebBucketName', region);
  await syncToS3('frontend/out', bucketName, region);

  const distId = await getStackOutput(stackName, 'CloudfrontDistributionId', region);
  await invalidate(distId, region);

  console.log('✅ Published');
}

// ... helper functions (run, getStackOutput, syncToS3, invalidate)

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

**Integration**:
```json
// package.json
{
  "scripts": {
    "deploy:dev": "ENVIRONMENT=dev ts-node infrastructure/lib/infra.ts deploy",
    "deploy:prod": "ENVIRONMENT=prod ts-node infrastructure/lib/infra.ts deploy",
    "publish:dev": "ENVIRONMENT=dev ts-node infrastructure/lib/infra.ts publish",
    "synth": "ENVIRONMENT=dev ts-node infrastructure/lib/infra.ts synth"
  }
}
```

**When to Use**:
- Simple projects (static frontends, single-stack)
- ≤5 commands
- No shared logic between commands worth abstracting
- Fast implementation preferred

**When to Migrate to 2-Tier**:
- Commands grow beyond ~200 lines total
- You need `--verbose`, `--dry-run`, or other shared flags
- Multiple commands share significant logic

---

## 2-Tier Architecture (Recommended for Most Projects)

**Structure**:
```
cli/
  bin/           # Tier 1: Argument parsing
  commands/      # Tier 2: Business logic + SDK calls
shared/
  env-loader.ts  # Simple utilities
  configs.ts
```

**Tier 1: CLI Binaries** - Entry points only
```typescript
// bin/ssm-params.ts
import { Command } from 'commander';
import { getParameter } from '../commands/ssm-params';

const program = new Command();

program
  .command('get <name>')
  .action(async (name: string) => {
    const value = await getParameter(name);
    console.log(value);
  });

program.parse();
```

**Tier 2: Commands** - Direct SDK usage
```typescript
// commands/ssm-params.ts
import { SSMClient, GetParameterCommand } from '@aws-sdk/client-ssm';
import { loadEnv } from '../shared/env-loader';

loadEnv();

const ssmClient = new SSMClient({ 
  region: process.env.CDK_DEFAULT_REGION 
});

export async function getParameter(name: string): Promise<string> {
  const command = new GetParameterCommand({ Name: name });
  const response = await ssmClient.send(command);
  return response.Parameter?.Value ?? '';
}
```

**When to Use**:
- Medium-sized projects
- 2-5 CLI tools
- Straightforward operations
- Faster development preferred

---

## 3-Tier Architecture (For Complex Projects)

Uses composition instead of inheritance — small focused modules that commands wire together.

**Structure**:
```
cli/
  bin/           # Tier 1: Argument parsing + error handling ONLY
  commands/      # Tier 2: Business logic, composes core modules
core/
  logger.ts          # Tier 3: Standalone utilities
  env.ts
  aws/
    ssm.ts
    s3.ts
```

**Tier 1: CLI Binaries** — Entry points only (NO business logic)
```typescript
// bin/ssm-params.ts
import { Command } from 'commander';
import { getParameter, exportParams } from '../commands/ssm-params';

const program = new Command();

program
  .command('get <name>')
  .option('-v, --verbose', 'verbose output')
  .action(async (name, opts) => {
    const value = await getParameter(name, { verbose: opts.verbose });
    console.log(value);
  });

program
  .command('export <stage> <service>')
  .action(async (stage, service) => {
    await exportParams(stage, service);
  });

program.parse();
```

**Tier 3: Core Modules** — Small, focused, no inheritance

Each module does one thing and exports plain functions or simple factory functions:

```typescript
// core/logger.ts
export function createLogger(verbose: boolean) {
  return {
    log: (msg: string) => { if (verbose) console.log(msg); },
    error: (msg: string) => console.error(msg),
  };
}
```

```typescript
// core/env.ts
export function loadEnv(stage: string): Record<string, string> {
  const envPath = `.env.${stage}`;
  // Load from file, fall back to process.env
  return { ...parseEnvFile(envPath), ...process.env };
}

export function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`${key} is required`);
  return value;
}
```

```typescript
// core/aws/ssm.ts
import { SSMClient, GetParameterCommand, GetParametersByPathCommand } from '@aws-sdk/client-ssm';

export function createSSMClient(region: string) {
  const client = new SSMClient({ region });

  return {
    async getParameter(name: string): Promise<string> {
      const res = await client.send(new GetParameterCommand({ Name: name }));
      return res.Parameter?.Value ?? '';
    },

    async getParametersByPath(path: string): Promise<Record<string, string>> {
      const res = await client.send(new GetParametersByPathCommand({ Path: path }));
      const params: Record<string, string> = {};
      for (const p of res.Parameters ?? []) {
        if (p.Name && p.Value) params[p.Name] = p.Value;
      }
      return params;
    },
  };
}
```

**Tier 2: Commands** — Compose core modules, contain all business logic

```typescript
// commands/ssm-params.ts
import { createLogger } from '../core/logger';
import { requireEnv } from '../core/env';
import { createSSMClient } from '../core/aws/ssm';

export async function getParameter(name: string, opts: { verbose?: boolean } = {}) {
  const log = createLogger(opts.verbose ?? false);
  const region = requireEnv('AWS_REGION');
  const ssm = createSSMClient(region);

  log.log(`Fetching parameter: ${name}`);
  return ssm.getParameter(name);
}

export async function exportParams(stage: string, service: string) {
  const region = requireEnv('AWS_REGION');
  const projectId = requireEnv('PROJECT_ID');
  const ssm = createSSMClient(region);

  const params = await ssm.getParametersByPath(`/${projectId}/${stage}/${service}/`);
  for (const [key, value] of Object.entries(params)) {
    const envKey = key.split('/').pop();
    console.log(`${envKey}=${value}`);
  }
}
```

**Why composition over inheritance**:
- Each module is independently testable — no base class to mock
- No hidden behavior from parent classes
- Easy to swap implementations (e.g., different cloud providers)
- Commands explicitly declare what they need — no implicit `this.log()` from a base class

**When to Use**:
- Large projects with 5+ CLI tools
- Multiple commands sharing core modules (SSM, S3, logging)
- Team environments needing consistent patterns

---

## Decision Guide

| Factor | 1-Tier | 2-Tier | 3-Tier |
|--------|--------|--------|--------|
| Project Size | Simple | Medium | Large |
| CLI Commands | ≤5 | 2-5 | 5+ |
| Team Size | 1 | 1-3 | 3+ |
| Complexity | Minimal | Moderate | Complex |
| Development Speed | Fastest | Fast | Slower initially |
| Reusability | None | Lower | Higher |
| Shared Logic | Minimal | Some | Significant |

**Start with 1-Tier** for static frontends and single-stack projects.
**Migrate to 2-Tier** when commands exceed ~200 lines or share significant logic.
**Migrate to 3-Tier** when:
- You have 5+ CLI tools
- Duplicating logic across commands
- Team needs consistent patterns
- Abstractions provide clear value

---

## Language-Specific Integration

**JavaScript/TypeScript** - `package.json`:
```json
{
  "scripts": {
    "deploy:dev": "ts-node cli/bin/deploy.ts --env=dev",
    "params:get": "ts-node cli/bin/ssm-params.ts get"
  }
}
```

**Python** - `pyproject.toml`:
```toml
[tool.poetry.scripts]
deploy-dev = "cli.bin.deploy:main"
params-get = "cli.bin.ssm_params:get_parameter"
```

**Makefile** - Universal:
```makefile
deploy-dev:
	python cli/bin/deploy.py --env=dev

params-get:
	python cli/bin/ssm_params.py get $(NAME)
```

---

## Related Patterns

- [Pure Functions](../../CORE_PRINCIPLES.md#1-prefer-pure-functions) - Apply to helper functions
- [Error Handling](../../CORE_PRINCIPLES.md#7-error-handling) - Fail fast on configuration errors

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
