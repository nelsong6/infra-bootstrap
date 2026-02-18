# infra-bootstrap

Shared bootstrap infrastructure for Azure-based applications. This repository provides foundational resources (Resource Group, DNS Zone) and a reusable Terraform module for deploying complete Azure applications.

## 🎯 Purpose

This repository implements an **infrastructure-app split architecture**:
- **Infra Repo** (this repo): Shared foundational resources used by all apps
- **App Repos**: Individual application deployments that reference this infrastructure

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│              infra-bootstrap (This Repo)                 │
│                                                          │
│  Shared Infrastructure (RG: "infra"):                    │
│  ✓ OpenTofu State Storage                               │
│  ✓ DNS Zone (romaine.life)                              │
│  ✓ Email DNS Records (MX, SPF, autodiscover)            │
│                                                          │
│  Reusable Module:                                        │
│  ✓ modules/azure-app - Complete app deployment          │
│                                                          │
│  State: tfstate4807/infra.tfstate                       │
└──────────────────────────────────────────────────────────┘
                        ▲
                        │ Remote State Reference
                        │
        ┌───────────────┼───────────────┐
        │               │               │
┌───────▼──────┐ ┌──────▼─────┐ ┌──────▼─────┐
│  workout-app │ │  notes-app │ │ future-app │
│              │ │            │ │            │
│ Uses module  │ │Uses module │ │Uses module │
│ from infra   │ │from infra  │ │from infra  │
└──────────────┘ └────────────┘ └────────────┘
```

## ✨ Features

### Shared Infrastructure
- **Resource Group**: Centralized resource management
- **DNS Zone**: Domain-wide DNS management
- **Email Configuration**: MX, SPF, and autodiscover records
- **State Management**: Centralized Terraform state in Azure Storage

### Azure App Module
A complete, production-ready application stack:
- 🌐 **Static Web App** - Frontend hosting (React, Vue, Angular, etc.)
- 💾 **Cosmos DB** - NoSQL database with free tier
- 🐳 **Container Apps** - Serverless backend API hosting
- 🔒 **Security** - Managed identities, RBAC, HTTPS
- 🌍 **DNS** - Custom domains with automatic SSL
- 🔄 **CI/CD** - GitHub Actions integration

## 📦 What's Included

```
infra-bootstrap/
├── bootstrap/              # Initial setup scripts
│   ├── 00-bootstrap.ps1    # Main entry point
│   ├── 01-config.ps1       # Configuration
│   ├── 02-azure-login.ps1  # Through 13-summary.ps1
│   └── README.md           # Complete bootstrap guide
├── modules/
│   └── azure-app/          # Reusable app module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── tofu/                   # Shared infrastructure (OpenTofu)
│   ├── provider.tf
│   ├── main.tf
│   ├── dns.tf              # DNS zone & records (managed in OpenTofu)
│   ├── output.tf           # Outputs for app repos
│   ├── auth.tf
│   └── variables.tf
├── docs/
│   ├── APP_REPO_SETUP.md   # Guide for new apps
│   └── MIGRATION.md        # Migration guide
└── README.md
```

## 🚀 Quick Start

### 1. Deploy Shared Infrastructure (One Time)

```bash
# Clone this repository
git clone https://github.com/nelsong6/infra-bootstrap.git
cd infra-bootstrap

# Run bootstrap (creates Azure AD App, OIDC, state storage)
.\bootstrap\00-bootstrap.ps1

# Deploy shared infrastructure via GitHub Actions or locally
cd tofu
tofu init
tofu apply
```

### 2. Create a New Application

See the complete guide: **[docs/APP_REPO_SETUP.md](docs/APP_REPO_SETUP.md)**

Quick example in your app repository:

```hcl
# Reference shared infrastructure
data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = "infra"
    storage_account_name = "tfstate4807"
    container_name       = "tfstate"
    key                  = "infra.tfstate"
  }
}

# Deploy your app
module "my_app" {
  source = "git::https://github.com/nelsong6/infra-bootstrap.git//modules/azure-app?ref=main"

  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  dns_zone_name       = data.terraform_remote_state.infra.outputs.dns_zone_name
  dns_zone_id         = data.terraform_remote_state.infra.outputs.dns_zone_id

  app_name                = "myapp"
  custom_domain_subdomain = "myapp"
  github_repo             = "owner/repo"
  container_image         = "ghcr.io/owner/repo/api:latest"

  cosmos_db_config = {
    database_name = "MyAppDB"
    containers = [{
      name                = "items"
      partition_key_paths = ["/userId"]
    }]
  }
}
```

That's it! This creates your complete application stack.

## 💰 Cost Optimization

Per application costs:
- Static Web App (Free): **$0/month**
- Cosmos DB (Free Tier): **$0/month** (400 RU/s, 25 GB)
- Container Apps: **~$0-5/month** (scales to zero when idle)
- Container Images: **$0** (hosted on GitHub Container Registry)

**Total: ~$0-5/month per app** (excluding the shared DNS zone at $0.50/month in the infra RG)

## 📚 Documentation

- **[App Repository Setup Guide](docs/APP_REPO_SETUP.md)** - Complete guide for creating new apps
- **[Azure App Module Documentation](modules/azure-app/README.md)** - Module API reference
- **[Migration Guide](docs/MIGRATION.md)** - Migrating existing resources

## 🔐 Security

- **Managed Identities**: No connection strings or keys
- **RBAC**: Role-based access control for all resources
- **HTTPS Only**: Automatic SSL certificates via Azure
- **OIDC**: GitHub Actions use OpenID Connect (no secrets)
- **Secrets Management**: GitHub secrets managed via Terraform

## 🛠️ Requirements

- **Terraform/OpenTofu**: >= 1.6.0
- **Azure CLI**: For bootstrap script
- **GitHub Token**: For GitHub provider
- **Azure Subscription**: With appropriate permissions

## 🌟 Benefits of This Architecture

### For Developers
✅ **Simple Setup**: One module call deploys entire app stack  
✅ **Consistent**: Same pattern for all applications  
✅ **Fast**: New app in minutes, not hours  
✅ **Local Dev**: CORS and localhost support built-in

### For Operations
✅ **Centralized**: Shared infrastructure managed in one place  
✅ **Isolated**: Each app has separate state file  
✅ **Scalable**: Easy to add new applications  
✅ **Maintainable**: Module updates benefit all apps

### For Organization
✅ **Cost Effective**: Free tier usage, scale-to-zero  
✅ **Secure**: Best practices baked in  
✅ **Production Ready**: HTTPS, RBAC, monitoring  
✅ **GitOps**: Infrastructure as code for everything

## 🔄 State Management

All Terraform state is stored in Azure Storage:

```
infra/tfstate4807/tfstate/
├── infra.tfstate           # Shared infrastructure (this repo)
├── workout-app.tfstate     # Workout app resources
├── notes-app.tfstate       # Notes app resources
└── future-app.tfstate      # Future app resources
```

Each app maintains independent state while referencing shared infrastructure.

## 📖 Example Applications

**Workout Tracker** (`workout-app` repository):
- Frontend: `workout.romaine.life`
- Backend: `api.workout.romaine.life`
- Database: Cosmos DB with workouts container
- State: `workout-app.tfstate`

**Future Apps**:
Simply create a new repository, add the module configuration, and deploy!

## 🤝 Contributing

1. Make changes to the module or shared infrastructure
2. Test changes with an example app
3. Update documentation
4. Create a pull request
5. Tag releases for module versioning

## 📝 Module Versioning

Pin your app to specific module versions:

```hcl
module "my_app" {
  source = "git::https://github.com/nelsong6/infra-bootstrap.git//modules/azure-app?ref=v1.0.0"
  # ...
}
```

## 🐛 Troubleshooting

### Common Issues

**"Remote state not found"**
- Ensure infra-bootstrap is deployed first
- Check backend configuration matches

**"DNS validation failed"**
- Wait for DNS propagation (1-2 hours)
- Verify nameservers at registrar

**"Resource already exists"**
- Use import to bring existing resources under management
- See [MIGRATION.md](docs/MIGRATION.md)

## 📞 Support

- **Issues**: File in this repository
- **Docs**: Check [docs/](docs/) directory
- **Module**: See [modules/azure-app/README.md](modules/azure-app/README.md)

## 📄 License

This repository provides infrastructure configuration for personal/organizational use.

---

## 🎯 Next Steps

1. ✅ **Deploy shared infrastructure** (bootstrap + terraform apply)
2. 📱 **Create your first app** - Follow [APP_REPO_SETUP.md](docs/APP_REPO_SETUP.md)
3. 🚀 **Deploy more apps** - Reuse the module for each new project
4. 📊 **Monitor costs** - Review Azure Cost Management
5. 🔒 **Review security** - Ensure RBAC and secrets are configured

**Ready to deploy? Start with the [App Repository Setup Guide](docs/APP_REPO_SETUP.md)!**
