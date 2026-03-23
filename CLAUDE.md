# infra-bootstrap

Root infrastructure repo. Creates shared resources consumed by all app repos.

## Architecture

- Landing page infra (SWA, DNS, custom domain) lives here, not in the landing-page repo
- The landing-page repo has a `trigger-infra.yml` workflow that triggers infra-bootstrap on push to `frontend/**`
- The `@` TXT record in dns.tf is named `apex` and combines SPF, Google verification, and SWA validation

## App Onboarding

The app module (`tofu/app/main.tf`) creates per-app: GitHub repo, Azure AD app registration + service principal (with Contributor, RBAC Admin, Key Vault Secrets Officer, App Configuration Data Owner, and Storage Blob Data Reader roles — all at subscription scope), OIDC federated credentials, and GitHub Actions variables (`ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `KEY_VAULT_NAME`, `TFSTATE_STORAGE_ACCOUNT`, `GOOGLE_CLIENT_ID`, `MICROSOFT_CLIENT_ID`).
Apps are added to the `for_each` list in the app module.

## Infrastructure Pattern

- Shared resources: Azure Container App Environment, Cosmos DB (free tier), App Configuration, DNS zone (romaine.life), Key Vault, User-Assigned Managed Identity (infra-shared-identity)
- Pipeline templates repo (nelsong6/pipeline-templates) has reusable GitHub Actions workflows
- App pattern: Static Web App (frontend) + route package consumed by shared API (`api` repo) + Cosmos DB. Per-app Container Apps have been decommissioned in favor of the shared always-on API

## Related Repos

- **infra-bootstrap** (this repo) — root infrastructure
- **api** — shared always-on backend consolidating all app backends into a single Container App
- **my-homepage**, **kill-me**, **bender-world**, **eight-queens**, **plant-agent** — app repos that consume shared infra
- **pipeline-templates** — reusable GitHub Actions workflows

## Change Log

- **2026-03-14** — Added plant-agent to the app module for_each list in tofu/main.tf
- **2026-03-14** — Removed `has_backend` variable from app module (was declared but never used); simplified `for_each` from map to plain string set
- **2026-03-14** — Removed all Spacelift references: deleted `.spacelift/` config, `bootstrap/setup-google-cloud.ps1`, cleaned bootstrap scripts, lock files, CLAUDE.md, README, and landing.tf comments
- **2026-03-14** — Per-app Azure AD app registrations: each app now gets its own `azuread_application` + `azuread_service_principal` with Contributor (subscription) and Key Vault Secrets User roles, replacing the shared global app registration that was hitting the 20 federated credential limit
- **2026-03-14** — Grant App Configuration Data Owner role to app SPs (needed for data-plane writes during tofu apply)
- **2026-03-14** — Add shared user-assigned managed identity (`infra-shared-identity`) with pre-assigned roles: Cosmos DB Data Contributor, App Config Data Reader, Key Vault Secrets User, Storage Blob Data Contributor (subscription scope). Apps attach this identity to Container Apps instead of creating their own role assignments. Upgrade app SP Key Vault role from Secrets User to Secrets Officer (for writing secrets during apply)
- **2026-03-22** — Added `api` to the app module `for_each` list — scaffolds the shared always-on backend repo (Azure AD app registration, OIDC credentials, GitHub Actions variables). Part of consolidating all app backends into a single Container App to eliminate cold starts (~$19/month for always-on 0.25 vCPU / 0.5 Gi).
- **2026-03-23** — Widened per-app OIDC principal RBAC Admin scope from `infra` resource group to subscription level. The previous scope prevented app pipelines from managing role assignments in their own resource groups (e.g. my-homepage couldn't grant the shared API storage blob access in `homepage-rg`).
- **2026-03-15** — Distribute Google and Microsoft OAuth client IDs as GitHub Actions variables (`GOOGLE_CLIENT_ID`, `MICROSOFT_CLIENT_ID`) to all app repos via the app module. Added plain (non-KV-reference) App Config keys for both (`google_oauth_client_id_plain`, `microsoft_oauth_client_id_plain`) so backends can read client IDs without Key Vault access. Added SPA redirect URIs to Microsoft OAuth app registration for plant-agent's MSAL.js redirect flow (`plants.romaine.life`, `localhost:5173`)
