# infra-bootstrap

Root infrastructure repo. Creates shared resources consumed by all app repos.

## Architecture

- Landing page infra (SWA, DNS, custom domain) lives here, not in the landing-page repo
- The landing-page repo has a `trigger-infra.yml` workflow that triggers infra-bootstrap on push to `frontend/**`
- The `@` TXT record in dns.tf is named `apex` and combines SPF, Google verification, and SWA validation

## App Onboarding

The app module (`tofu/app/main.tf`) creates per-app: GitHub repo, Azure AD app registration + service principal, OIDC federated credentials, and GitHub Actions variables (`ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `KEY_VAULT_NAME`). Apps are added to the `for_each` list in the app module.

By default, apps also get heavy web roles via the `app/web/` sub-module: Contributor, RBAC Admin, Key Vault Secrets Officer, App Configuration Data Owner, Storage Blob Data Reader, Cosmos DB Data Reader, Graph app management, and additional variables (`TFSTATE_STORAGE_ACCOUNT`, `GOOGLE_CLIENT_ID`). Setting `ci_only = true` skips the web sub-module entirely — the app gets only OIDC identity + Key Vault Secrets User (read-only). Used for CLI tools like fzt that need CI auth but have no web presence.

## Infrastructure Pattern

- Shared resources: Azure Container App Environment, Cosmos DB (free tier), App Configuration, DNS zone (romaine.life), Key Vault, User-Assigned Managed Identity (infra-shared-identity)
- Pipeline templates repo (nelsong6/pipeline-templates) has reusable GitHub Actions workflows
- App pattern: Static Web App (frontend) + route package consumed by shared API (`api` repo) + Cosmos DB. Per-app Container Apps have been decommissioned in favor of the shared always-on API

## Related Repos

- **infra-bootstrap** (this repo) — root infrastructure
- **api** — shared always-on backend consolidating all app backends into a single Container App
- **my-homepage**, **kill-me**, **bender-world**, **eight-queens**, **plant-agent**, **fzt-showcase** — app repos that consume shared infra
- **diagrams** — interactive architecture documentation site at `diagrams.romaine.life`
- **pipeline-templates** — reusable GitHub Actions workflows
