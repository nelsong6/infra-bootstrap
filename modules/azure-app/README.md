# Azure App Module

A reusable Terraform module for deploying complete Azure-based applications with:
- **Frontend**: Azure Static Web App
- **Database**: Azure Cosmos DB (with free tier support)
- **Backend API**: Azure Container Apps (serverless containers)
- **DNS**: Custom domain configuration
- **CI/CD**: GitHub Actions integration

## Features

✅ **Complete Application Stack**
- Static Web App for frontend hosting (React, Vue, Angular, etc.)
- Cosmos DB for NoSQL database storage
- Container Apps for backend API hosting
- Automatic HTTPS with custom domains
- CORS configuration out of the box

✅ **Production Ready**
- Managed identities for secure authentication
- RBAC-based access control
- Custom domain with automatic SSL certificates
- DNS records automatically configured
- GitHub Actions secrets/variables management

✅ **Cost Optimized**
- Cosmos DB free tier (400 RU/s, 25 GB storage)
- Container Apps scale to zero
- Static Web App free tier
- Pay only for what you use

✅ **Developer Friendly**
- Single module call deploys entire stack
- Local development support with CORS
- GitHub integration for CI/CD
- Easy to customize and extend

## Usage

### Prerequisites

1. **Infra Repository**: Deploy the shared infrastructure first (Resource Group, DNS Zone)
2. **GitHub Token**: Set `GITHUB_TOKEN` environment variable for GitHub provider
3. **Azure Authentication**: Configure Azure credentials (OIDC or Service Principal)

### Basic Example

```hcl
# Reference the infra remote state
data "terraform_remote_state" "infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = "infra"
    storage_account_name = "tfstate4807"
    container_name       = "tfstate"
    key                  = "infra.tfstate"
  }
}

# Deploy your app using the module
module "my_app" {
  source = "git::https://github.com/nelsong6/infra-bootstrap.git//modules/azure-app?ref=main"

  # Required: Infra outputs
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  dns_zone_name       = data.terraform_remote_state.infra.outputs.dns_zone_name
  dns_zone_id         = data.terraform_remote_state.infra.outputs.dns_zone_id

  # Required: App configuration
  app_name                = "myapp"
  custom_domain_subdomain = "myapp"
  github_repo             = "myuser/myapp-repo"
  container_image         = "ghcr.io/myuser/myapp/api:latest"

  # Required: Cosmos DB configuration
  cosmos_db_config = {
    database_name = "MyAppDB"
    containers = [
      {
        name                = "items"
        partition_key_paths = ["/userId"]
      }
    ]
  }

  # Optional: CORS configuration
  frontend_allowed_origins = [
    "http://localhost:5173",
    "http://localhost:4173"
  ]

  # Optional: User access for local development
  user_principal_id = "your-user-object-id"

  # Optional: Custom tags
  tags = {
    Team = "Engineering"
    Cost = "Project-A"
  }
}
```

### Advanced Example with Multiple Containers

```hcl
module "workout_app" {
  source = "git::https://github.com/nelsong6/infra-bootstrap.git//modules/azure-app?ref=main"

  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  dns_zone_name       = data.terraform_remote_state.infra.outputs.dns_zone_name
  dns_zone_id         = data.terraform_remote_state.infra.outputs.dns_zone_id

  app_name                = "workout"
  custom_domain_subdomain = "workout"
  github_repo             = "nelsong6/workout-app"
  container_image         = "ghcr.io/nelsong6/workout-app/api:latest"

  # Multiple Cosmos DB containers
  cosmos_db_config = {
    database_name = "WorkoutTrackerDB"
    containers = [
      {
        name                = "workouts"
        partition_key_paths = ["/userId"]
        max_throughput      = 1000
      },
      {
        name                = "exercises"
        partition_key_paths = ["/category"]
        max_throughput      = 500
      }
    ]
  }

  # Custom container resources
  container_cpu           = 0.5
  container_memory        = "1.0Gi"
  container_min_replicas  = 1
  container_max_replicas  = 10

  # Development origins
  frontend_allowed_origins = [
    "http://localhost:5173",
    "http://localhost:3000"
  ]

  environment = "Production"
  
  tags = {
    Team    = "Fitness"
    Project = "WorkoutTracker"
  }
}
```

## Input Variables

### Required Variables

| Name | Description | Type |
|------|-------------|------|
| `app_name` | Application name (e.g., 'workout', 'notes') | `string` |
| `resource_group_name` | Azure resource group name from infra | `string` |
| `location` | Azure region from infra | `string` |
| `dns_zone_name` | DNS zone name from infra | `string` |
| `dns_zone_id` | DNS zone ID from infra | `string` |
| `custom_domain_subdomain` | Subdomain for custom domain | `string` |
| `github_repo` | GitHub repository (owner/repo) | `string` |
| `container_image` | Container image for backend API | `string` |
| `cosmos_db_config` | Cosmos DB configuration object | `object` |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `github_branch` | GitHub branch for OIDC | `string` | `"main"` |
| `container_cpu` | CPU allocation (cores) | `number` | `0.25` |
| `container_memory` | Memory allocation | `string` | `"0.5Gi"` |
| `container_min_replicas` | Min replicas (0 = scale to zero) | `number` | `0` |
| `container_max_replicas` | Max replicas | `number` | `3` |
| `container_port` | Container port | `number` | `3000` |
| `cosmos_db_free_tier` | Enable free tier | `bool` | `true` |
| `frontend_allowed_origins` | Additional CORS origins | `list(string)` | `[]` |
| `static_web_app_sku` | Static Web App SKU | `string` | `"Free"` |
| `user_principal_id` | User Object ID for local dev | `string` | `null` |
| `environment` | Environment name | `string` | `"Production"` |
| `tags` | Additional resource tags | `map(string)` | `{}` |

## Outputs

### Static Web App
- `static_web_app_id` - Resource ID
- `static_web_app_name` - Resource name
- `static_web_app_url` - Default Azure URL
- `static_web_app_custom_domain_url` - Custom domain URL

### Cosmos DB
- `cosmos_db_account_id` - Account resource ID
- `cosmos_db_account_name` - Account name
- `cosmos_db_endpoint` - Connection endpoint
- `cosmos_db_database_name` - Database name
- `cosmos_db_container_names` - List of container names

### Container App
- `container_app_id` - Resource ID
- `container_app_name` - Resource name
- `container_app_url` - Default Azure URL
- `container_app_custom_domain_url` - Custom domain URL
- `container_app_identity_principal_id` - Managed identity principal ID

### DNS
- `frontend_custom_domain` - Frontend domain name
- `backend_custom_domain` - Backend API domain name

### Summary
- `deployment_summary` - Complete deployment information

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure App Module                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐      ┌──────────────────┐               │
│  │  Static Web App  │      │  Container App   │               │
│  │   (Frontend)     │◄────►│   (Backend API)  │               │
│  │                  │      │                  │               │
│  │  Custom Domain:  │      │  Custom Domain:  │               │
│  │  app.domain.com  │      │ api.app.domain...│               │
│  └──────────────────┘      └────────┬─────────┘               │
│           │                          │                         │
│           │                          │ Managed Identity        │
│           │                          │ (RBAC Auth)             │
│           │                          ▼                         │
│           │                 ┌──────────────────┐               │
│           │                 │   Cosmos DB      │               │
│           └────────────────►│  (NoSQL DB)      │               │
│                             │                  │               │
│                             │  Free Tier:      │               │
│                             │  400 RU/s        │               │
│                             └──────────────────┘               │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              DNS Zone (from infra)                       │  │
│  │  • CNAME: app → Static Web App                          │  │
│  │  • CNAME: api.app → Container App                       │  │
│  │  • TXT: asuid.api.app → Verification                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           GitHub Actions Integration                     │  │
│  │  • Secrets: COSMOS_DB_ENDPOINT                          │  │
│  │  • Variables: Resource names, config                    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## What This Module Creates

1. **Static Web App** - Frontend hosting with automatic HTTPS
2. **Cosmos DB Account** - NoSQL database with free tier
3. **Cosmos DB Database** - Database within the account
4. **Cosmos DB Containers** - Collections with partition keys
5. **Container App Environment** - Shared infrastructure for containers
6. **Container App** - Backend API with managed identity
7. **DNS Records** - CNAME and TXT records for custom domains
8. **Custom Domain Bindings** - SSL certificates and domain validation
9. **RBAC Role Assignments** - Permissions for managed identities
10. **GitHub Secrets/Variables** - CI/CD configuration

## DNS Configuration

The module automatically creates:
- `{subdomain}.{dns_zone}` → Static Web App (e.g., `workout.romaine.life`)
- `api.{subdomain}.{dns_zone}` → Container App (e.g., `api.workout.romaine.life`)
- `asuid.api.{subdomain}.{dns_zone}` → Verification TXT record

## Security

- **Managed Identities**: No connection strings or keys
- **RBAC**: Fine-grained access control
- **HTTPS Only**: Automatic SSL certificates
- **CORS**: Configurable allowed origins
- **Secrets Management**: GitHub secrets via Terraform

## Cost Estimate (Free Tier)

- Static Web App (Free): **$0/month**
- Cosmos DB (Free Tier): **$0/month** (400 RU/s, 25 GB)
- Container Apps: **~$0-5/month** (scales to zero, pay per use)
- DNS Zone: **$0.50/month** (per zone, shared across apps)

**Total per app: ~$0-5/month** (excluding DNS zone)

## Migration from Monolithic Setup

If you're migrating from a monolithic Terraform setup:

1. Create the module in your infra repository
2. Set up the app repository with module instantiation
3. Import existing resources into the module state
4. Verify with `terraform plan` (should show no changes)
5. Remove resources from old configuration

See the [migration guide](../../docs/MIGRATION.md) for detailed steps.

## Troubleshooting

### DNS Propagation Issues
- Wait 1-2 hours for DNS changes to propagate
- Verify nameservers are configured correctly
- Check DNS records: `nslookup {subdomain}.{domain}`

### Custom Domain Validation Fails
- Ensure DNS records are created before domain binding
- Verify TXT record for Container App: `asuid.api.{subdomain}`
- Check that the 90-second delay is sufficient

### Container App Not Starting
- Verify container image is accessible
- Check environment variables are set correctly
- Review Container App logs in Azure Portal

### Cosmos DB Access Denied
- Ensure managed identity has Data Contributor role
- Verify RBAC role assignments are created
- Wait a few minutes for permissions to propagate

## Support

For issues, questions, or contributions:
- File an issue in the infra-bootstrap repository
- Check the [main documentation](../../README.md)
- Review Azure documentation for specific services

## License

This module is part of the infra-bootstrap repository.
