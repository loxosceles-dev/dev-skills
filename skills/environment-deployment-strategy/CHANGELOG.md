# Changelog — environment-deployment-strategy

## 2026-09-04

- Merged CORS section from `environment-deployment` (now deleted): when local dev hits the deployed dev API, the dev backend must allow both `localhost` and the deployed dev frontend origin in CORS config
- `environment-deployment` skill deleted — it was a duplicate of this one, less complete (missing the CORS section)
