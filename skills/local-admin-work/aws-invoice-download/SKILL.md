---
name: aws-invoice-download
description: Download AWS invoices across all organization accounts. Apply when the user asks to download, fetch, or manage AWS invoices.
---

# AWS Invoice Download

**This is a reference pattern.** Learn from the approach, adapt to your context — don't copy verbatim.

**Problem**: AWS management accounts see consolidated invoices that duplicate member account invoices, and downloading them manually per account/month is tedious.

**Solution**: Dockerized Python script that iterates all org accounts, deduplicates by invoice ID, and organizes PDFs by billing period.

---

## Steps

1. Ensure the user has an active AWS SSO session for their organization management account. Check with `aws sts get-caller-identity --profile <profile>`. If expired, run `aws sso login --profile <profile>`. Look up the profile name in `~/.aws/config`.

2. Ask the user for the number of months and output directory.

3. Build the Docker image from `scripts/` in this skill directory if it doesn't exist:
   ```bash
   docker build -t aws-invoices <path-to-scripts/>
   ```

4. Run the container, passing the AWS profile and mounting credentials:
   ```bash
   docker run --rm \
     -e AWS_PROFILE=<profile> \
     -v ~/.aws:/root/.aws:ro \
     -v ~/.aws/sso/cache:/root/.aws/sso/cache \
     -v ~/.aws/cli/cache:/root/.aws/cli/cache \
     -v <output-dir>:/output \
     aws-invoices --months <N>
   ```

## How It Works

- Lists all org accounts, processes member accounts first
- Deduplicates by invoice ID — member account names win over management account consolidated copies
- Downloads PDFs via pre-signed URLs from `invoicing get-invoice-pdf`
- Organizes into `MM-YYYY/` folders

## Implementation

When modifying or debugging, read the source files in `scripts/`:
- `scripts/download_invoices.py` — main script
- `scripts/Dockerfile` — container definition (AWS CLI v2 multi-stage build)

## Rebuilding

If the script or Dockerfile changes: `docker rmi aws-invoices`

---

## Progressive Improvement

If the developer corrects a behavior that this skill should have prevented, suggest a specific amendment to this skill to prevent the same correction in the future.
