# infra-bootstrap

Root infrastructure repo. Creates shared resources consumed by all app repos.

## Architecture

- Landing page infra (SWA, DNS, custom domain) lives here, not in the landing-page repo
- The landing-page repo has a `trigger-infra.yml` workflow that triggers infra-bootstrap on push to `frontend/**`
- The `@` TXT record in dns.tf is named `apex` and combines SPF, Google verification, and SWA validation

## App Onboarding

The app module (`tofu/app/main.tf`) creates per-app: GitHub repo, OIDC credentials, GitHub Actions variables.
Apps are added to the `for_each` list in the app module.

## Infrastructure Pattern

- Shared resources: Azure Container App Environment, Cosmos DB (free tier), App Configuration, DNS zone (romaine.life), Key Vault
- Pipeline templates repo (nelsong6/pipeline-templates) has reusable GitHub Actions workflows
- my-homepage is the reference app pattern: Static Web App (frontend) + Container App (backend) + Cosmos DB

## Related Repos

- **infra-bootstrap** (this repo) — root infrastructure
- **my-homepage**, **kill-me**, **bender-world**, **eight-queens**, **plant-agent** — app repos that consume shared infra
- **pipeline-templates** — reusable GitHub Actions workflows

## Change Log

- **2026-03-14** — Added plant-agent to the app module for_each list in tofu/main.tf
