# infra-bootstrap

Root infrastructure repo. Creates shared resources consumed by all app repos.

## Architecture
- Landing page infra (SWA, DNS, custom domain) lives here, not in the landing-page repo
- Landing page has no Spacelift stack — deploys go through infra-bootstrap's after_apply hook (configured in `.spacelift/config.yml`)
- The landing-page repo has a `trigger-infra.yml` workflow that triggers infra-bootstrap on push to `frontend/**`
- The `@` TXT record in dns.tf is named `apex` and combines SPF, Google verification, and SWA validation

## App Onboarding

The app module (`tofu/app/main.tf`) creates per-app: GitHub repo, Spacelift stack, OIDC credentials, GitHub Actions variables.
Apps are added to the `for_each` list in the app module.

## Infrastructure Pattern

- Shared resources: Azure Container App Environment, Cosmos DB (free tier), App Configuration, DNS zone (romaine.life), Key Vault
- App repos consume these via Spacelift stack dependency injection (TF_VAR_infra_* variables)
- Pipeline templates repo (nelsong6/pipeline-templates) has reusable GitHub Actions workflows
- my-homepage is the reference app pattern: Static Web App (frontend) + Container App (backend) + Cosmos DB

## Related Repos

- **infra-bootstrap** (this repo) — root infrastructure
- **my-homepage**, **kill-me**, **bender-world**, **eight-queens**, **plant-agent** — app repos that consume shared infra
- **pipeline-templates** — reusable GitHub Actions workflows

## Spacelift CLI

Nelson has `spacectl` installed and helper functions in his PowerShell profile:

- `sl-auth` — fetches Spacelift API key creds from Azure Key Vault (`romaine-kv`) and sets env vars
- `sl-logs [stack]` — fetches latest run logs for a stack (defaults to `infra-bootstrap`). Auto-calls `sl-auth` if needed.
- Endpoint: <https://nelsong6.app.us.spacelift.io>

## Change Log

- **2026-03-14** — Added plant-agent to the app module for_each list in tofu/main.tf
