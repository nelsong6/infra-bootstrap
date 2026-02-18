# Bootstrap Guide: OpenTofu Infrastructure Setup

Complete guide for bootstrapping Azure infrastructure with GitHub Actions OIDC authentication and OpenTofu state management.

## 🎯 Overview

The bootstrap process creates all foundational infrastructure needed to manage your Azure resources with OpenTofu via GitHub Actions:

1. **Azure AD App Registration** with OIDC for GitHub Actions (no secrets needed!)
2. **Service Principal** with appropriate permissions
3. **Federated Credentials** for GitHub Actions authentication
4. **Azure Storage** for OpenTofu state backend
5. **Infrastructure Resource Group** for shared resources

This is a **one-time setup** - after this, all infrastructure changes are managed through OpenTofu.

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and authenticated (`az login`)
- PowerShell 5.1 or later
- GitHub repository created
- Azure subscription with Owner/Contributor permissions

### Step 1: Run Bootstrap Script

From the repository root:

```powershell
.\bootstrap\00-bootstrap.ps1
```

The script will:
- Prompt for configuration (GitHub repo, Azure subscription, etc.)
- Create Azure AD App Registration
- Configure OIDC for GitHub Actions
- Set up OpenTofu state storage
- Create resource groups and permissions
- Generate backend.tf configuration

**Save the output values** - you'll need them for GitHub!

### Step 2: Configure GitHub Repository

Go to **Settings → Secrets and variables → Actions → Variables tab**

Add these repository variables:

| Variable Name | Value | Source |
|---------------|-------|--------|
| `AZURE_CLIENT_ID` | (App/Client ID) | Bootstrap output |
| `AZURE_TENANT_ID` | (Tenant ID) | Bootstrap output |
| `AZURE_SUBSCRIPTION_ID` | (Subscription ID) | Bootstrap output |

### Step 3: Deploy Infrastructure via GitHub Actions

1. Go to **Actions** tab in your GitHub repository
2. Select **"OpenTofu Infrastructure"** workflow
3. Click **"Run workflow"** dropdown
4. Choose action:
   - **`plan`** - Preview changes (safe, read-only)
   - **`apply`** - Create/update infrastructure
   - **`destroy`** - Delete all resources
5. Click **"Run workflow"**

### Step 4: Retrieve Outputs

After successful `apply`:
1. Go to the workflow run details
2. Check the **Summary** tab for output values
3. Add any needed outputs as GitHub Variables for other workflows

## 📋 Script Sections

The bootstrap process is modularized into numbered sections for clarity and maintainability:

| File | Description |
|------|-------------|
| **00-bootstrap.ps1** | Main orchestrator - runs all sections in order |
| **01-config.ps1** | Configuration variables (Azure, GitHub, resource naming) |
| **02-azure-login.ps1** | Authenticate to Azure and set subscription context |
| **03-app-registration.ps1** | Create or verify Azure AD App Registration |
| **04-service-principal.ps1** | Create or verify Service Principal for the app |
| **05-role-assignment.ps1** | Grant Owner role to the Service Principal |
| **06-federated-credentials.ps1** | Setup OIDC federated credentials for GitHub Actions |
| **07-app-permissions.ps1** | Add API permissions and grant admin consent |
| **08-storage-backend.ps1** | Create Azure Storage for OpenTofu state backend |
| **12-generate-backend.ps1** | Generate backend.tf configuration file |
| **13-summary.ps1** | Display summary and next steps |

## ⚙️ Customization

To customize the bootstrap process:

1. **Before running**: Edit **01-config.ps1** to change default values
2. **After running**: Modify individual section files and re-run specific sections
3. **Advanced**: Comment out sections you don't need in **00-bootstrap.ps1**

All variables use `$script:` scope to be available across all sections.

## 🔄 Workflow Behavior

### Automatic Triggers

- **Pull Requests**: Runs `tofu plan` and comments the results
- **Push to main** (when tofu files change): Runs `tofu plan` only
- **Manual**: You choose `plan`, `apply`, or `destroy`

### Safety Features

The workflow only runs `apply` or `destroy` when:
- ✅ Manually triggered via GitHub UI
- ✅ On `main` branch
- ✅ Action is explicitly selected

This prevents accidental infrastructure changes.

## 🌐 DNS Management

### ⚠️ Important: DNS Zone Setup

**DNS zones should be managed in OpenTofu, not with bootstrap scripts.**

#### For New DNS Zones

Add to your `dns.tf`:

```hcl
resource "azurerm_dns_zone" "main" {
  name                = "yourdomain.com"
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Environment = "Production"
    Project     = "YourProject"
  }
}
```

#### For Existing DNS Zones

Use an import block in your OpenTofu configuration:

```hcl
import {
  to = azurerm_dns_zone.main
  id = "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.Network/dnsZones/{zone-name}"
}

resource "azurerm_dns_zone" "main" {
  name                = "yourdomain.com"
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Environment = "Production"
    Project     = "YourProject"
  }
}
```

Then run:
```bash
tofu plan -generate-config-out=imported.tf  # Optional: auto-generate config
tofu plan                                    # Verify import
tofu apply                                   # Complete import
```

After import, manage all DNS records through OpenTofu in your `dns.tf` file.

## 🔍 Troubleshooting

### Authentication Issues

**"Error: Unauthorized" in GitHub Actions**

Solutions:
1. Verify GitHub variables are set correctly (case-sensitive!)
2. Check repository name matches exactly in federated credential
3. Verify federated credential exists:
   ```powershell
   az ad app federated-credential list --id $APP_ID
   ```
4. Ensure the workflow is running from the correct branch

**"Error: Insufficient permissions"**

Solution - grant Owner role:
```powershell
az role assignment create `
  --assignee $SP_ID `
  --role Owner `
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### State Management Issues

**"Error: Failed to get existing workspaces"**

The state backend isn't configured. Check:
1. Storage account exists: `az storage account show -n tfstate4807 -g infra`
2. Container exists: `az storage container show -n tfstate --account-name tfstate4807`
3. backend.tf is correctly generated and committed

**"State lock" errors**

Someone else is running OpenTofu or a previous run failed:
```powershell
# List locks
az storage blob list --account-name tfstate4807 --container-name tfstate --query "[?properties.lease.status=='locked']"

# If stuck, you can break the lease (careful!)
az storage blob lease break --blob-name infra.tfstate --container-name tfstate --account-name tfstate4807
```

**Note**: Replace `tfstate4807` with your actual storage account name from the bootstrap output.

### Bootstrap Script Issues

**"Resource already exists"**

The bootstrap has been run before. Options:
1. Use the existing resources (note the IDs from Azure Portal)
2. Delete and re-run (destructive):
   ```powershell
   az ad app delete --id $APP_ID
   az group delete --name infra --yes
   ```

### DNS Issues

**DNS not resolving after deployment**

1. Verify nameservers at registrar match Azure DNS:
   ```powershell
   az network dns zone show --name yourdomain.com --resource-group your-rg --query nameServers
   ```
2. Check propagation (can take 24-48 hours):
   ```powershell
   nslookup -type=SOA yourdomain.com
   ```
3. Verify DNS records are created:
   ```powershell
   az network dns record-set list --zone-name yourdomain.com --resource-group your-rg
   ```

## 📚 Common Tasks

### View Current Infrastructure

```powershell
# List all resources in the infra resource group
az resource list --resource-group infra --output table

# View Azure AD App details
az ad app show --id $APP_ID

# Check federated credentials
az ad app federated-credential list --id $APP_ID -o table

# View OpenTofu state
cd tofu
tofu state list
tofu show
```

### Re-run Specific Bootstrap Sections

```powershell
# Re-run just one section (from bootstrap directory)
cd bootstrap
. .\01-config.ps1  # Load config first
. .\08-storage-backend.ps1  # Then run specific section
```

### Reset Everything (Nuclear Option)

⚠️ **WARNING**: This deletes ALL infrastructure!

```powershell
# 1. Delete resource group
az group delete --name infra --yes --no-wait

# 2. Delete Azure AD App
az ad app delete --id $APP_ID

# 3. Remove GitHub variables
# Go to Settings → Actions → Variables and delete all

# 4. Re-run bootstrap
.\bootstrap\00-bootstrap.ps1
```

## 🔒 Security Notes

### How OIDC Works

1. **GitHub Actions** requests an OIDC token from GitHub's identity provider
2. **Azure** validates the token against the federated credential
3. If the subject claim matches your repo/branch, **Azure grants temporary access**
4. **OpenTofu** uses those credentials to deploy infrastructure
5. **Tokens expire** automatically after the workflow completes

### Security Benefits

- ✅ **No secrets stored** - OIDC tokens are temporary and auto-generated
- ✅ **Federated credential** - Only trusts your specific repo and branch
- ✅ **Manual approval** - Workflow requires explicit action for destructive operations
- ✅ **Auditable** - All actions logged in GitHub and Azure Activity Log
- ✅ **Time-limited** - Credentials only valid during workflow execution
- ✅ **Revocable** - Delete the federated credential to immediately revoke access

### Best Practices

1. **Use branch protection** - Require PR reviews before merging to main
2. **Limit workflow permissions** - Only grant what's needed
3. **Monitor Activity Logs** - Review Azure Activity Log regularly
4. **Rotate carefully** - If you need to recreate the app, update GitHub variables immediately
5. **Use separate apps** - Consider different apps for dev/staging/prod

## 🎓 How It All Fits Together

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                          │
│  (Requests OIDC token with subject claim)                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Token includes:
                     │ - repo: owner/repo
                     │ - ref: refs/heads/main
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    Azure AD / Entra ID                      │
│  Federated Credential validates:                            │
│  - Subject matches: repo:owner/repo:ref:refs/heads/main     │
│  - Token is from GitHub                                     │
│  - Token hasn't expired                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ If valid, grants temporary access
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  Service Principal                          │
│  Has Owner role on subscription                             │
│  Can create/modify/delete resources                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ OpenTofu uses credentials
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Azure Resources                           │
│  - Resource Groups                                          │
│  - DNS Zones                                                │
│  - Storage Accounts                                         │
│  - Container Apps                                           │
│  - Cosmos DB                                                │
│  - Static Web Apps                                          │
└─────────────────────────────────────────────────────────────┘
```

## 📖 Next Steps

After bootstrap is complete:

1. ✅ **GitHub Variables** are configured
2. 📝 **Create your OpenTofu configuration** in the `tofu/` directory
3. 🚀 **Push to GitHub** - The workflow will run automatically
4. 📊 **Review the plan** in the PR comments
5. ✅ **Merge and apply** - Use workflow dispatch for apply
6. 🌐 **Configure DNS** - Import existing zones or create new ones
7. 🎉 **Deploy your application** - Infrastructure is ready!

## 🆘 Getting Help

- **Script fails**: Check error messages and verify Azure CLI authentication
- **Workflow fails**: Check Actions tab → failed run → detailed logs
- **Permission errors**: Ensure you have Owner/Contributor on subscription
- **GitHub variables**: Must be in Variables tab, not Secrets
- **DNS issues**: See DNS Management section above

## 📞 Support Resources

- **Azure AD OIDC**: [Microsoft Docs - Workload Identity Federation](https://learn.microsoft.com/en-us/azure/active-directory/workload-identities/workload-identity-federation)
- **GitHub Actions**: [Configuring OIDC in Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- **OpenTofu**: [OpenTofu Documentation](https://opentofu.org/docs/)
- **Import Blocks**: [OpenTofu Import Blocks](https://opentofu.org/docs/language/import/)

---

**Pro Tip**: Save your `$APP_ID`, `$TENANT_ID`, and `$SUBSCRIPTION_ID` in a secure note. You'll need them if you want to troubleshoot or manage resources manually later!

## 📝 Variables Reference

All configuration variables are defined in **01-config.ps1**:

| Variable | Description | Example |
|----------|-------------|---------|
| `$APP_NAME` | Azure AD App display name | "GitHub-Actions-OpenTofu" |
| `$REPO` | GitHub repository (owner/name) | "nelsong6/kill-me" |
| `$SUBSCRIPTION_ID` | Azure subscription ID | Auto-detected or manual |
| `$TFSTATE_RG_NAME` | Infrastructure resource group | "infra" |
| `$STORAGE_NAME` | State storage account | "tfstate" + random suffix |
| `$CONTAINER_NAME` | State storage container | "tfstate" |

## 🎯 Success Criteria

You'll know bootstrap succeeded when:

- ✅ Script completes without errors
- ✅ GitHub variables are set
- ✅ GitHub Actions workflow runs successfully
- ✅ OpenTofu plan shows your infrastructure
- ✅ OpenTofu apply creates resources
- ✅ State is stored in Azure Storage

**Happy bootstrapping! 🚀**
