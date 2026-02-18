# infra-bootstrap

Bootstrap for setting up some cheap/free app services in Azure.

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
