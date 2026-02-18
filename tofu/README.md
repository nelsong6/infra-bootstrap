# Terraform/OpenTofu Infrastructure Configuration

This directory contains Infrastructure as Code (IaC) for the Workout Tracker application.

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `main.tf` | Core infrastructure: Static Web App, Cosmos DB |
| `container-apps.tf` | Backend API hosting with Azure Container Apps |
| `dns.tf` | Custom domain configuration for workout.romaine.life |
| `auth.tf` | OIDC authentication for GitHub Actions |
| `provider.tf` | Terraform provider configuration |
| `variables.tf` | Input variables |
| `output.tf` | Output values for CI/CD |
| `bootstrap.ps1` | Bootstrap script for initial Azure AD setup |
| `bootstrap-dns.ps1` | **NEW:** Bootstrap script for DNS zone creation |

## 🚀 Quick Start

### Initial Setup (One-Time)

1. **Bootstrap Azure AD & Terraform State**
   ```powershell
   cd tofu
   .\bootstrap.ps1
   ```
   This creates the App Registration and Terraform state storage.

2. **Configure GitHub Repository**
   - Go to: Settings → Secrets and variables → Actions → Variables
   - Add the variables displayed by the bootstrap script:
     - `AZURE_CLIENT_ID`
     - `AZURE_TENANT_ID`
     - `AZURE_SUBSCRIPTION_ID`

3. **Deploy Infrastructure**
   ```powershell
   tofu init
   tofu plan
   tofu apply
   ```

### Custom Domain Setup (Optional)

To use `workout.romaine.life` instead of the default Azure URLs:

1. **Bootstrap DNS Zone**
   ```powershell
   .\bootstrap-dns.ps1
   ```

2. **Update Domain Registrar**
   - Configure nameservers (displayed by bootstrap script)
   - Wait for DNS propagation (1-48 hours)

3. **Apply DNS Configuration**
   ```powershell
   tofu apply
   ```

4. **Verify Setup**
   ```powershell
   # Test domains
   curl https://workout.romaine.life
   curl https://api.workout.romaine.life/health
   ```

**For detailed instructions, see:** [CUSTOM_DOMAIN_SETUP.md](./CUSTOM_DOMAIN_SETUP.md)

## 📋 Documentation

- [BOOTSTRAP.md](./BOOTSTRAP.md) - Initial Azure AD and GitHub setup
- [CUSTOM_DOMAIN_SETUP.md](./CUSTOM_DOMAIN_SETUP.md) - Custom domain configuration
- [CORS_SETUP.md](./CORS_SETUP.md) - CORS configuration notes

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                      │
│                       (workout-rg)                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Static Web App  │────────▶│  Container App   │          │
│  │    (Frontend)    │  HTTPS  │   (Backend API)  │          │
│  │  React + Vite    │         │   Node.js + SDK  │          │
│  └──────────────────┘         └──────────────────┘          │
│          │                             │                     │
│          │                             │                     │
│          │                    ┌────────▼────────┐            │
│          │                    │   Cosmos DB     │            │
│          └───────────────────▶│  (NoSQL, Free)  │            │
│              (for frontend     └─────────────────┘            │
│               static hosting)                                 │
│                                                               │
│  ┌──────────────────────────────────────────────┐            │
│  │          Azure DNS Zone                      │            │
│  │  - workout.romaine.life → Static Web App    │            │
│  │  - api.workout.romaine.life → Container App │            │
│  └──────────────────────────────────────────────┘            │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 🔐 Security & Authentication

### GitHub Actions → Azure
- **Method:** OIDC (Workload Identity Federation)
- **No secrets stored** - Uses federated credentials
- **Configured in:** `auth.tf` and `bootstrap.ps1`

### Container App → Cosmos DB
- **Method:** Managed Identity (RBAC)
- **No connection strings** - Uses Azure Identity SDK
- **Role:** Cosmos DB Data Contributor

### Static Web App & Container App
- **SSL:** Azure-managed certificates (automatic, free)
- **CORS:** Configured in `container-apps.tf`

## 🌍 Deployed Resources

After running `tofu apply`, these resources are created:

| Resource | Type | Purpose |
|----------|------|---------|
| `workout-rg` | Resource Group | Container for all resources |
| `workout-app-*` | Static Web App | Frontend hosting (React app) |
| `workout-cosmos-*` | Cosmos DB Account | NoSQL database |
| `WorkoutTrackerDB` | Cosmos DB Database | Database container |
| `workouts` | Cosmos DB Container | Workout data storage |
| `workout-env-*` | Container App Environment | Backend hosting infrastructure |
| `workout-api` | Container App | Backend API (Node.js) |
| `romaine.life` | DNS Zone | Custom domain management *(optional)* |

## 💰 Cost Estimation

### Free Tier Resources
- ✅ **Static Web Apps:** Free tier (100GB bandwidth/month)
- ✅ **Cosmos DB:** Free tier (1000 RU/s, 25GB storage)

### Pay-Per-Use Resources
- 💵 **Container Apps:** ~$5-10/month (with scale-to-zero enabled)
- 💵 **Azure DNS:** ~$0.50/month per zone + $0.40 per million queries

**Estimated Total:** $5-11/month

## 🔄 CI/CD Integration

The infrastructure is deployed automatically via GitHub Actions:

**Workflow:** `.github/workflows/terraform.yml`

**Triggers:**
- Manual workflow dispatch (plan/apply/destroy)
- Pull requests (plan only)
- Push to main (plan only, when .tf files change)

**Outputs automatically configured in GitHub:**
- `STATIC_WEB_APP_NAME`
- `RESOURCE_GROUP_NAME`
- `COSMOS_DB_DATABASE_NAME`
- `COSMOS_DB_CONTAINER_NAME`

## 🛠️ Common Operations

### View Current Infrastructure
```powershell
# List all resources
az resource list --resource-group workout-rg --output table

# Check Static Web App
az staticwebapp show --name workout-app-* --resource-group workout-rg

# Check Container App status
az containerapp show --name workout-api --resource-group workout-rg
```

### View Logs
```powershell
# Container App logs (live)
az containerapp logs show \
  --name workout-api \
  --resource-group workout-rg \
  --follow
```

### Update Container App
```powershell
# Scale replicas
az containerapp update \
  --name workout-api \
  --resource-group workout-rg \
  --min-replicas 0 \
  --max-replicas 5
```

### Destroy Everything
```powershell
# Via Terraform
tofu destroy

# Or manually delete resource group
az group delete --name workout-rg --yes --no-wait
```

## 🐛 Troubleshooting

### "Error: Unauthorized" in GitHub Actions
- Verify GitHub variables are set correctly
- Check federated credential matches repository name
- Ensure service principal has proper roles

### "Error: Backend initialization required"
```powershell
tofu init -reconfigure
```

### "Error: Resource already exists"
```powershell
# Import existing resource
tofu import azurerm_resource_group.workout /subscriptions/.../resourceGroups/workout-rg
```

### Custom Domain Issues
See [CUSTOM_DOMAIN_SETUP.md](./CUSTOM_DOMAIN_SETUP.md) troubleshooting section.

## 📚 Additional Resources

- [Azure Static Web Apps Documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Azure Cosmos DB Documentation](https://learn.microsoft.com/en-us/azure/cosmos-db/)
- [OpenTofu Documentation](https://opentofu.org/docs/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 🎯 Environment Variables

These are automatically configured by Terraform:

**Backend Container App:**
- `COSMOS_DB_ENDPOINT` - Cosmos DB endpoint URL
- `COSMOS_DB_DATABASE_NAME` - Database name
- `COSMOS_DB_CONTAINER_NAME` - Container name
- `FRONTEND_URL` - Frontend URL (for CORS validation)
- `PORT` - Container port (3000)

**GitHub Actions (via outputs):**
- `AZURE_CLIENT_ID` - Service principal client ID
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

---

**Questions?** Check the documentation files in this directory or review the inline comments in the `.tf` files.
