# OpenTofu Shared Infrastructure Configuration

This directory contains Infrastructure as Code (IaC) for the **shared foundational resources** used across all applications.

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `main.tf` | Core shared resources: Resource Group, DNS Zone |
| `dns.tf` | Domain-wide DNS configuration (email, MX, SPF records) |
| `auth.tf` | Azure client configuration for OIDC authentication |
| `provider.tf` | OpenTofu provider and backend configuration |
| `variables.tf` | Input variables (minimal for shared infrastructure) |
| `output.tf` | Output values for app repositories to consume |
| `terraform.tfvars` | Variable values (GitHub repo reference) |

## 🚀 Quick Start

### Initial Setup (One-Time)

**Prerequisites:**
- Azure subscription with Owner/Contributor permissions
- Azure CLI authenticated (`az login`)
- Bootstrap process completed (see [../bootstrap/README.md](../bootstrap/README.md))
- GitHub repository variables configured (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`)

### Deploy Shared Infrastructure

**Option 1: Via GitHub Actions (Recommended)**

1. Go to **Actions** tab in GitHub
2. Select **"OpenTofu Infrastructure"** workflow
3. Click **"Run workflow"**
4. Choose action:
   - `plan` - Preview changes
   - `apply` - Deploy/update infrastructure
   - `destroy` - Remove all resources
5. Click **"Run workflow"**

**Option 2: Locally**

```powershell
cd tofu
tofu init
tofu plan
tofu apply
```

## 🏗️ Architecture

This shared infrastructure provides foundational resources for all applications:

```
┌─────────────────────────────────────────────────────────────┐
│           Shared Infrastructure (Resource Group: infra)      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ Resource Group (infra)                                  │
│     - Centralized resource management                       │
│     - Azure location: eastus2                               │
│                                                              │
│  ✅ DNS Zone (romaine.life)                                 │
│     - Domain-wide DNS management                            │
│     - Nameservers configured at registrar                   │
│                                                              │
│  ✅ Email DNS Records                                       │
│     - MX records (Namecheap Private Email)                  │
│     - SPF record for authentication                         │
│     - Autoconfig/Autodiscover for email clients            │
│                                                              │
│  ✅ OpenTofu State Backend                                  │
│     - Azure Storage Account: tfstate4807                    │
│     - Container: tfstate                                    │
│     - State file: infra.tfstate                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                        ▲
                        │ Remote State Reference
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼──────┐ ┌──────▼─────┐ ┌──────▼─────┐
│  workout-app │ │  notes-app │ │ future-app │
│              │ │            │ │            │
│ References   │ │References  │ │References  │
│ infra state  │ │infra state │ │infra state │
└──────────────┘ └────────────┘ └────────────┘
```

## 📋 What's Managed Here

### Resources Defined as Data Sources
- **Resource Group**: Created by bootstrap script, referenced here
- **DNS Zone**: Created by bootstrap script, referenced here

### Resources Managed by OpenTofu
- **Email DNS Records**: MX, SPF, autoconfig, autodiscover
- Future shared resources (load balancers, shared app insights, etc.)

## 🔐 Security & Authentication

### GitHub Actions → Azure
- **Method:** OIDC (Workload Identity Federation)
- **No secrets stored** - Uses federated credentials
- **Configured in:** `auth.tf` and bootstrap scripts

### Backend State Storage
- **Authentication:** OIDC (`use_oidc = true`)
- **State file:** `infra.tfstate`
- **Access:** Restricted to service principal with proper roles

## 🌍 Outputs for App Repositories

This infrastructure exposes outputs that app repositories consume via remote state:

| Output | Description | Used By Apps For |
|--------|-------------|------------------|
| `resource_group_name` | Name of shared resource group | Deploying resources |
| `resource_group_location` | Azure region | Resource placement |
| `resource_group_id` | Resource group ID | Resource references |
| `dns_zone_name` | Domain name (romaine.life) | Custom domain setup |
| `dns_zone_id` | DNS zone resource ID | Creating DNS records |
| `dns_zone_nameservers` | Azure DNS nameservers | Domain verification |
| `azure_subscription_id` | Azure subscription ID | Provider config |
| `azure_tenant_id` | Azure tenant ID | Provider config |

### Example: App Repository Usage

```hcl
# In your app repository's Terraform configuration
data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = "infra"
    storage_account_name = "tfstate4807"
    container_name       = "tfstate"
    key                  = "infra.tfstate"
    use_oidc             = true
  }
}

# Use the outputs
module "my_app" {
  source = "git::https://github.com/nelsong6/infra-bootstrap.git//modules/azure-app?ref=main"
  
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  dns_zone_name       = data.terraform_remote_state.infra.outputs.dns_zone_name
  dns_zone_id         = data.terraform_remote_state.infra.outputs.dns_zone_id
  
  # ... app-specific configuration
}
```

## 💰 Cost Estimation

### Shared Infrastructure Costs
- 💵 **Azure DNS Zone:** ~$0.50/month per zone + $0.40 per million queries
- ✅ **Storage Account (State):** Free tier (first 5GB, minimal transactions)
- ✅ **Resource Group:** Free (container for resources)

**Estimated Total:** ~$0.50-1.00/month

*Individual app costs are managed in their respective repositories.*

## 🔄 CI/CD Integration

**Workflow:** `.github/workflows/terraform.yml` (in root of repo)

**Triggers:**
- Manual workflow dispatch (`plan`, `apply`, `destroy`)
- Pull requests (plan only)
- Push to main (plan only, when .tf files change)

**Safety:**
- Destructive operations (`apply`, `destroy`) require manual approval
- Protected branch rules prevent unauthorized changes
- State locking prevents concurrent modifications

## 🛠️ Common Operations

### View Current Infrastructure

```powershell
# List all resources in shared resource group
az resource list --resource-group infra --output table

# View DNS zone details
az network dns zone show --name romaine.life --resource-group infra

# Check DNS nameservers
az network dns zone show --name romaine.life --resource-group infra --query nameServers

# View DNS records
az network dns record-set list --zone-name romaine.life --resource-group infra --output table
```

### View State

```powershell
cd tofu
tofu state list
tofu show
```

### Add New Shared Resources

1. Add resource definition to appropriate `.tf` file
2. Run `tofu plan` to preview changes
3. Commit and push to trigger GitHub Actions
4. Review plan in Actions output
5. Manually trigger `apply` action

### Update DNS Records

Edit `dns.tf` and follow the standard workflow (plan → review → apply).

## 🐛 Troubleshooting

### "Error: Resource Group not found"
The bootstrap process must create the resource group first:
```powershell
cd bootstrap
.\00-bootstrap.ps1
```

### "Error: DNS Zone not found"
Ensure the DNS zone exists and is in the correct resource group:
```powershell
az network dns zone list --output table
```

### "Error: Backend initialization required"
Re-initialize the backend:
```powershell
tofu init -reconfigure
```

### "Error: Unauthorized" in GitHub Actions
- Verify GitHub variables are set correctly (`AZURE_CLIENT_ID`, etc.)
- Check federated credential matches repository name
- Ensure service principal has proper roles

## 📚 Documentation

- **[Bootstrap Guide](../bootstrap/README.md)** - Initial setup and prerequisites
- **[App Repo Setup](../docs/APP_REPO_SETUP.md)** - Creating new applications
- **[Azure App Module](../modules/azure-app/README.md)** - Reusable app deployment module
- **[Migration Guide](../docs/MIGRATION.md)** - Migrating existing resources

## 🎯 Design Principles

### Why Shared Infrastructure?

**Benefits:**
- ✅ **Single Source of Truth**: One DNS zone for all apps
- ✅ **Cost Efficient**: Shared resources reduce duplication
- ✅ **Centralized Management**: Domain-wide settings in one place
- ✅ **Consistent Configuration**: All apps use same foundation
- ✅ **Simplified Onboarding**: New apps reference existing infrastructure

### What Belongs Here?

**Include:**
- ✅ Resource groups used by multiple apps
- ✅ DNS zones and domain-wide DNS records
- ✅ Shared networking (VNets, subnets)
- ✅ Shared monitoring (Application Insights, Log Analytics)
- ✅ Centralized security resources

**Exclude:**
- ❌ App-specific resources (Static Web Apps, Container Apps, Cosmos DB)
- ❌ App-specific DNS records (subdomains)
- ❌ App-specific configuration
- ❌ Application code or deployment

*App-specific resources should use the `azure-app` module in their own repositories.*

## 🔒 State Management

### Backend Configuration

```hcl
backend "azurerm" {
  resource_group_name  = "infra"
  storage_account_name = "tfstate4807"
  container_name       = "tfstate"
  key                  = "infra.tfstate"
  use_oidc             = true
}
```

### State File Structure

```
Azure Storage Account: tfstate4807
└── Container: tfstate
    ├── infra.tfstate           # ← This infrastructure
    ├── workout-app.tfstate     # App-specific state
    ├── notes-app.tfstate       # App-specific state
    └── future-app.tfstate      # App-specific state
```

Each repository maintains its own state file in the shared storage account.

## 📖 Next Steps

After deploying shared infrastructure:

1. ✅ **Verify DNS nameservers** at your domain registrar
2. 📱 **Create app repositories** - Follow [APP_REPO_SETUP.md](../docs/APP_REPO_SETUP.md)
3. 🚀 **Deploy applications** - Use the `azure-app` module
4. 📊 **Monitor costs** - Review Azure Cost Management
5. 🔒 **Review security** - Ensure RBAC and OIDC are configured

## 🆘 Getting Help

- **Bootstrap Issues**: See [bootstrap/README.md](../bootstrap/README.md)
- **App Deployment**: See [docs/APP_REPO_SETUP.md](../docs/APP_REPO_SETUP.md)
- **Module Reference**: See [modules/azure-app/README.md](../modules/azure-app/README.md)

---

**Questions?** Check the documentation files in the parent directory or review inline comments in the `.tf` files.
