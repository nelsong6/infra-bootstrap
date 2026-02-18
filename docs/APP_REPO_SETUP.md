# App Repository Setup Guide

This guide explains how to set up a new application repository that uses the shared infrastructure from `infra-bootstrap`.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    infra-bootstrap Repository                   │
│                     (Shared Infrastructure)                     │
├─────────────────────────────────────────────────────────────────┤
│  • Resource Group                                               │
│  • DNS Zone (romaine.life)                                      │
│  • Email DNS Records                                            │
│  • Azure App Module (reusable)                                  │
│                                                                 │
│  State: tfstate4807/infra.tfstate                              │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │ Remote State
                              │ Data Source
                              │
┌─────────────────────────────┼───────────────────────────────────┐
│                    App Repository (e.g., workout-app)           │
│                     (Application Resources)                     │
├─────────────────────────────────────────────────────────────────┤
│  • Static Web App (Frontend)                                    │
│  • Cosmos DB (Database)                                         │
│  • Container Apps (Backend API)                                 │
│  • App-specific DNS Records                                     │
│  • GitHub Integration                                           │
│                                                                 │
│  State: tfstate4807/workout-app.tfstate                        │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Infra Bootstrap Deployed**: The `infra-bootstrap` repository must be deployed first
2. **GitHub Repository Created**: Create your app repository (e.g., `workout-app`)
3. **Azure Access**: Same service principal/OIDC access as infra repo
4. **GitHub Token**: Set `GITHUB_TOKEN` environment variable for GitHub provider

## Step-by-Step Setup

### 1. Create Application Repository

```bash
# Create new repository on GitHub
# Clone it locally
git clone https://github.com/nelsong6/your-app-name.git
cd your-app-name
```

### 2. Create Directory Structure

```bash
mkdir tofu
mkdir -p .github/workflows
```

Your repo structure should look like:

```
your-app-name/
├── .github/
│   └── workflows/
│       └── terraform.yml
├── tofu/
│   ├── provider.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── src/                    # Your application code
│   ├── frontend/
│   └── backend/
└── README.md
```

### 3. Create Terraform Configuration

#### `tofu/provider.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate4807"
    container_name       = "tfstate"
    key                  = "your-app-name.tfstate"  # Change this!
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

provider "azuread" {
  use_oidc = true
}

provider "github" {
  owner = local.github_owner
  # Token read from GITHUB_TOKEN environment variable
}
```

#### `tofu/main.tf`

```hcl
# ============================================================================
# Application Infrastructure
# ============================================================================

# Local variables
locals {
  github_parts     = split("/", var.github_repo)
  github_owner     = local.github_parts[0]
  github_repo_name = local.github_parts[1]
}

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

# Deploy application using the azure-app module
module "app" {
  source = "git::https://github.com/nelsong6/infra-bootstrap.git//modules/azure-app?ref=main"

  # Shared infrastructure from remote state
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
  location            = data.terraform_remote_state.infra.outputs.resource_group_location
  dns_zone_name       = data.terraform_remote_state.infra.outputs.dns_zone_name
  dns_zone_id         = data.terraform_remote_state.infra.outputs.dns_zone_id

  # Application configuration
  app_name                = var.app_name
  custom_domain_subdomain = var.app_name
  github_repo             = var.github_repo
  container_image         = var.container_image

  # Cosmos DB configuration
  cosmos_db_config = var.cosmos_db_config

  # CORS configuration
  frontend_allowed_origins = var.frontend_allowed_origins

  # Optional: User access for local development
  user_principal_id = var.user_principal_id

  # Tags
  environment = var.environment
  tags        = var.tags
}
```

#### `tofu/variables.tf`

```hcl
# ============================================================================
# Application Variables
# ============================================================================

variable "app_name" {
  description = "Application name (used for resource naming and subdomain)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in format: owner/repo"
  type        = string
}

variable "container_image" {
  description = "Container image for backend API"
  type        = string
}

variable "cosmos_db_config" {
  description = "Cosmos DB configuration"
  type = object({
    database_name = string
    containers = list(object({
      name                = string
      partition_key_paths = list(string)
      max_throughput      = optional(number, 1000)
    }))
  })
}

variable "frontend_allowed_origins" {
  description = "Additional CORS origins for local development"
  type        = list(string)
  default     = []
}

variable "user_principal_id" {
  description = "User Object ID for local development Cosmos DB access"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Production"
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = {}
}
```

#### `tofu/outputs.tf`

```hcl
# ============================================================================
# Application Outputs
# ============================================================================

output "frontend_url" {
  value       = module.app.static_web_app_custom_domain_url
  description = "Frontend application URL"
}

output "backend_url" {
  value       = module.app.container_app_custom_domain_url
  description = "Backend API URL"
}

output "cosmos_db_endpoint" {
  value       = module.app.cosmos_db_endpoint
  description = "Cosmos DB endpoint"
}

output "deployment_summary" {
  value       = module.app.deployment_summary
  description = "Deployment summary"
}
```

### 4. Create terraform.tfvars

Create `tofu/terraform.tfvars` (add to .gitignore):

```hcl
app_name        = "workout"  # Change this!
github_repo     = "nelsong6/workout-app"  # Change this!
container_image = "ghcr.io/nelsong6/workout-app/api:latest"  # Change this!

cosmos_db_config = {
  database_name = "WorkoutTrackerDB"  # Change this!
  containers = [
    {
      name                = "workouts"
      partition_key_paths = ["/userId"]
    }
  ]
}

frontend_allowed_origins = [
  "http://localhost:5173",
  "http://localhost:4173"
]

# Optional: For local development
# user_principal_id = "your-azure-user-object-id"

tags = {
  Team    = "Engineering"
  Project = "WorkoutTracker"
}
```

### 5. Create GitHub Actions Workflow

#### `.github/workflows/terraform.yml`

```yaml
name: Terraform

on:
  push:
    branches: [ main ]
    paths:
      - 'tofu/**'
      - '.github/workflows/terraform.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'tofu/**'
  workflow_dispatch:

permissions:
  id-token: write
  contents: read
  pull-requests: write

env:
  ARM_CLIENT_ID: ${{ vars.AZURE_CLIENT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ vars.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ vars.AZURE_TENANT_ID }}
  ARM_USE_OIDC: true

jobs:
  terraform:
    name: Terraform Plan & Apply
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ./tofu

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
          terraform_wrapper: false

      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format Check
        run: terraform fmt -check
        continue-on-error: true

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        id: plan
        run: terraform plan -no-color -out=tfplan
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve tfplan
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 6. Configure GitHub Secrets and Variables

In your app repository settings, configure:

**Variables** (Settings → Secrets and variables → Actions → Variables):
- `AZURE_CLIENT_ID`: Same as infra repo
- `AZURE_SUBSCRIPTION_ID`: Same as infra repo
- `AZURE_TENANT_ID`: Same as infra repo

**Secrets**:
- `GITHUB_TOKEN`: Automatically provided by GitHub Actions

### 7. Initial Deployment

```bash
# Navigate to tofu directory
cd tofu

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply if everything looks good
terraform apply
```

## Example: Complete Workout App Setup

Here's a complete example for the workout tracker application:

**Directory Structure:**
```
workout-app/
├── .github/workflows/terraform.yml
├── tofu/
│   ├── provider.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── src/
│   ├── frontend/        # React/Vue/etc app
│   └── backend/         # Node.js API
├── .gitignore
└── README.md
```

**terraform.tfvars:**
```hcl
app_name        = "workout"
github_repo     = "nelsong6/workout-app"
container_image = "ghcr.io/nelsong6/workout-app/api:latest"

cosmos_db_config = {
  database_name = "WorkoutTrackerDB"
  containers = [
    {
      name                = "workouts"
      partition_key_paths = ["/userId"]
    }
  ]
}

frontend_allowed_origins = [
  "http://localhost:5173",
  "http://localhost:4173"
]

user_principal_id = "cf57d57d-1411-4f59-b517-e9a8600b140a"

environment = "Production"

tags = {
  Team    = "Fitness"
  Project = "WorkoutTracker"
}
```

## What Gets Created

When you deploy your app, the module creates:

1. **Static Web App**: `workout-app-{random}` at `workout.romaine.life`
2. **Cosmos DB**: `workout-cosmos-{random}` with your database and containers
3. **Container App Environment**: `workout-env-{random}`
4. **Container App**: `workout-api` at `api.workout.romaine.life`
5. **DNS Records**: CNAME records for custom domains
6. **GitHub Secrets/Variables**: Automatically configured for CI/CD
7. **RBAC Roles**: Managed identity permissions

## Costs

- Static Web App (Free): **$0/month**
- Cosmos DB (Free Tier): **$0/month** (400 RU/s, 25 GB)
- Container Apps: **~$0-5/month** (scales to zero)

**Total per app: ~$0-5/month**

## Migrating Existing Resources

If you have existing resources in the infra repo, see [MIGRATION.md](./MIGRATION.md) for import instructions.

## Troubleshooting

### "Remote state not found"
- Ensure infra-bootstrap has been deployed first
- Verify the backend configuration matches (`infra.tfstate`)

### "DNS Zone not found"
- Check that the DNS zone exists in the infra repo
- Verify the zone name matches in both repos

### "Module not found"
- Ensure the module source URL is correct
- Use `?ref=main` to pin to a specific branch/tag
- Check that infra-bootstrap repo is accessible

### GitHub Actions Failing
- Verify Azure credentials are set as repository variables
- Ensure GITHUB_TOKEN permissions are set correctly
- Check that the service principal has necessary permissions

## Next Steps

1. Deploy your application code (frontend/backend)
2. Set up CI/CD for application builds
3. Configure monitoring and logging
4. Set up custom error pages
5. Add application-specific environment variables

## Support

For issues or questions:
- Check the [main README](../README.md)
- Review module documentation: [modules/azure-app/README.md](../modules/azure-app/README.md)
- File an issue in the infra-bootstrap repository
