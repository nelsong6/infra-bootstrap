# PARKED — awaiting org migration

This Helm wrapper (and `../arc-runners/`) is deployed-ready for Actions
Runner Controller but not currently wired up to ArgoCD.

## Why parked

First attempted 2026-04-19 with a GitHub App scoped to a personal account
(`nelsong6`). ARC needs `administration: write` permission to mint runner
registration tokens, which is a repo-level permission on personal accounts.
GitHub didn't cleanly surface the "accept new permissions" flow for an
installation on the owner's own account, so the controller's registration
call kept returning 403.

Deferred until the `romaine-life` org migration (May 2026). At org scope,
runners register against the org via the `organization_self_hosted_runners`
permission — cleaner accept-perms flow, one scale set covers all 18 repos.

## Pickup

After the org exists + romaine-life-app is reinstalled there:

1. Re-add ArgoCD Applications: copy the two manifests below back into
   `k8s/apps/`:
   - `arc-controller.yaml` — sync-wave 0
   - `arc-runners.yaml` — sync-wave 1
2. Edit `../arc-runners/values.yaml`: change `githubConfigUrl` to
   `https://github.com/romaine-life` (org root) and `runnerScaleSetName`
   to something like `romaine-runners`.
3. Re-generate the GitHub App installation ID (it will be new under the
   org) and store in `romaine-kv` as `github-app-installation-id`.
4. Grant the app `organization_self_hosted_runners: write`.
5. Flip workflows that want self-hosted: `runs-on: romaine-runners`.

Tracked by: nelsong6/infra-bootstrap#29 (blocked on nelsong6/ambience#10).
