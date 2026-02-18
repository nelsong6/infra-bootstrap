# infra-bootstrap

Bootstrap for setting up some cheap/free app services in Azure.

## OpenTofu Workflows

This repository uses two separate workflows for infrastructure management:

### 1. PR Plan Validation (`tofu-pr-plan.yml`)

**Trigger:** Automatically runs on pull requests that modify `tofu/**` files

**Purpose:** Validates infrastructure changes before merging

**What it does:**
- Runs `tofu plan` to validate proposed changes
- Posts plan results as a PR comment with full output
- Only validates - never applies changes to production
- Can be cancelled if new commits are pushed (concurrent PRs)

**Next Steps after PR approval:**
- Merge the PR to enable deployment
- Use the Production Deploy workflow to apply changes

### 2. Production Deploy (`tofu-prod-deploy.yml`)

**Trigger:** Manual only - via GitHub Actions UI

**Purpose:** Deploy approved infrastructure changes to production

**What it does:**
- Provides three action options:
  - `plan` - Review changes before applying (default)
  - `apply` - Apply changes to production (requires approval)
  - `destroy` - Destroy infrastructure (requires approval)
- Always runs a plan first to show what will change
- Requires manual approval via GitHub Environment protection before applying
- Only applies if there are actual changes detected

**How to use:**
1. Go to Actions → "Tofu Production Deploy"
2. Click "Run workflow"
3. Select the action (plan/apply/destroy)
4. Review the plan output
5. If action is "apply" or "destroy", approve the deployment when prompted

**Environment Protection:**
The `prod` environment should be configured with required reviewers in GitHub Settings → Environments to ensure production changes are approved before deployment.

## Security

### Secret Scanning

This repository includes automated secret scanning using [Gitleaks](https://github.com/gitleaks/gitleaks) to prevent accidental commits of sensitive information.

- **Automatic PR checks**: Every pull request is automatically scanned for secrets before merging
- **Push protection**: Scans run on pushes to main/master branches
- **Configuration**: The `.gitleaks.toml` file contains custom rules and allowlists

If the scan detects a potential secret, the PR check will fail and you'll need to remove the secret before merging.

#### Testing Locally

You can test for secrets locally before committing:

```bash
# Install Gitleaks (if not already installed)
# Windows (using Scoop):
scoop install gitleaks

# Or download from: https://github.com/gitleaks/gitleaks/releases

# Run scan
gitleaks detect --source . --verbose
```
