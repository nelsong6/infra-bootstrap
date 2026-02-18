# Migration Guide

This guide helps you migrate existing workout app resources from the monolithic infra-bootstrap setup to the new modular architecture.

## Overview

**Before**: All resources (infra + app) managed in `infra-bootstrap` repository  
**After**: Infra resources in `infra-bootstrap`, app resources in `workout-app` using the module

## Migration Strategy

We'll use Terraform's state management to move resources without recreating them (no downtime!).

## Prerequisites

- ✅ Backup current state file
- ✅ Have access to both repos (infra-bootstrap and workout-app)
- ✅ Azure credentials configured
- ✅ GitHub token available

## Step 1: Backup Everything

```bash
# Backup the current state
cd infra-bootstrap/tofu
terraform state pull > backup-state-$(date +%Y%m%d-%H%M%S).json

# Backup the current Terraform files
cd ..
git checkout -b backup-before-refactor
git add -A
git commit -m "Backup before refactoring to module architecture"
git push origin backup-before-refactor
```

## Step 2: Update Infra Repository State

The infra repository backend has changed from `terraform.tfstate` to `infra.tfstate`. We need to migrate the state:

```bash
cd infra-bootstrap/tofu

# Initialize with new backend configuration
terraform init -migrate-state

# This will prompt you to migrate from terraform.tfstate to infra.tfstate
# Answer "yes" when prompted
```

## Step 3: Remove App Resources from Infra State

Now we'll remove the app-specific resources from the infra state (they'll be imported in the app repo):

```bash
cd infra-bootstrap/tofu

# Remove Static Web App
terraform state rm azurerm_static_web_app.workout

# Remove Cosmos DB resources
terraform state rm azurerm_cosmosdb_account.workout
terraform state rm azurerm_cosmosdb_sql_database.workout
terraform state rm azurerm_cosmosdb_sql_container.workouts
terraform state rm azurerm_cosmosdb_sql_role_assignment.user_data_contributor

# Remove Container App resources
terraform state rm azurerm_container_app_environment.workout
terraform state rm azurerm_container_app.workout_api
terraform state rm azurerm_cosmosdb_sql_role_assignment.container_app_cosmos

# Remove app-specific DNS records
terraform state rm azurerm_dns_cname_record.frontend
terraform state rm azurerm_dns_cname_record.backend
terraform state rm azurerm_dns_txt_record.backend_verification

# Remove custom domain bindings
terraform state rm azurerm_static_web_app_custom_domain.frontend
terraform state rm azurerm_container_app_custom_domain.backend

# Remove time_sleep
terraform state rm time_sleep.wait_for_dns

# Remove GitHub integration
terraform state rm github_actions_secret.cosmos_db_endpoint
terraform state rm github_actions_variable.cosmos_db_database_name
terraform state rm github_actions_variable.cosmos_db_container_name
terraform state rm github_actions_variable.static_web_app_name
terraform state rm github_actions_variable.resource_group_name

# Remove role assignments
terraform state rm azurerm_role_assignment.github_actions_static_web_app

# Verify what's left (should only be shared infrastructure)
terraform state list
# Expected output:
# data.azurerm_client_config.current
# data.azurerm_dns_zone.main
# data.azurerm_resource_group.main (references "infra" RG)
# azurerm_dns_cname_record.autoconfig
# azurerm_dns_cname_record.autodiscover
# azurerm_dns_mx_record.email
# azurerm_dns_txt_record.spf
# random_string.suffix
```

## Step 4: Apply Infra Changes

The infra repo now only manages shared resources:

```bash
cd infra-bootstrap/tofu

# Plan should show removal of app resources (already removed from state)
terraform plan

# Apply to finalize
terraform apply

# Verify outputs work
terraform output
```

## Step 5: Set Up Workout App Repository

```bash
# Clone or navigate to workout-app repo
cd ../..
git clone https://github.com/nelsong6/workout-app.git
cd workout-app

# Create tofu directory
mkdir -p tofu
```

Create the Terraform configuration as described in [APP_REPO_SETUP.md](./APP_REPO_SETUP.md).

## Step 6: Initialize App Repo

```bash
cd workout-app/tofu

# Create terraform.tfvars
cat > terraform.tfvars << 'EOF'
app_name        = "workout"
github_repo     = "nelsong6/workout-app"
container_image = "ghcr.io/nelsong6/kill-me/workout-api:latest"

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
  Project = "WorkoutTracker"
}
EOF

# Initialize
terraform init
```

## Step 7: Import Existing Resources into Module

Since the resources already exist in Azure, we need to import them into the app repo's state:

```bash
cd workout-app/tofu

# Get resource IDs from Azure (you'll need these)
# Or use Azure Portal to find the resource IDs

# Import Static Web App
terraform import 'module.app.azurerm_static_web_app.frontend' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.Web/staticSites/workout-app-XXXXXX"

# Import Cosmos DB Account
terraform import 'module.app.azurerm_cosmosdb_account.main' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.DocumentDB/databaseAccounts/workout-cosmos-XXXXXX"

# Import Cosmos DB Database
terraform import 'module.app.azurerm_cosmosdb_sql_database.main' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.DocumentDB/databaseAccounts/workout-cosmos-XXXXXX/sqlDatabases/WorkoutTrackerDB"

# Import Cosmos DB Container
terraform import 'module.app.azurerm_cosmosdb_sql_container.containers["workouts"]' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.DocumentDB/databaseAccounts/workout-cosmos-XXXXXX/sqlDatabases/WorkoutTrackerDB/containers/workouts"

# Import Container App Environment
terraform import 'module.app.azurerm_container_app_environment.main' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.App/managedEnvironments/workout-env-XXXXXX"

# Import Container App
terraform import 'module.app.azurerm_container_app.api' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.App/containerApps/workout-api"

# Import DNS records
terraform import 'module.app.azurerm_dns_cname_record.frontend' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.Network/dnszones/romaine.life/CNAME/workout"

terraform import 'module.app.azurerm_dns_cname_record.backend' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.Network/dnszones/romaine.life/CNAME/api.workout"

terraform import 'module.app.azurerm_dns_txt_record.backend_verification' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.Network/dnszones/romaine.life/TXT/asuid.api.workout"

# Import custom domain bindings
terraform import 'module.app.azurerm_static_web_app_custom_domain.frontend' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.Web/staticSites/workout-app-XXXXXX/customDomains/workout.romaine.life"

terraform import 'module.app.azurerm_container_app_custom_domain.backend' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.App/containerApps/workout-api/customDomains/api.workout.romaine.life"

# Import role assignments (get IDs from Azure Portal)
terraform import 'module.app.azurerm_cosmosdb_sql_role_assignment.user_data_contributor[0]' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.DocumentDB/databaseAccounts/workout-cosmos-XXXXXX/sqlRoleAssignments/ROLE-ASSIGNMENT-ID"

terraform import 'module.app.azurerm_cosmosdb_sql_role_assignment.container_app_cosmos' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.DocumentDB/databaseAccounts/workout-cosmos-XXXXXX/sqlRoleAssignments/ROLE-ASSIGNMENT-ID"

terraform import 'module.app.azurerm_role_assignment.github_actions_static_web_app' \
  "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/workout-rg/providers/Microsoft.Web/staticSites/workout-app-XXXXXX/providers/Microsoft.Authorization/roleAssignments/ROLE-ASSIGNMENT-ID"

# Import random_string (note: this might fail, and that's okay - it will recreate with same value)
terraform import 'module.app.random_string.suffix' XXXXXX

# Import GitHub resources
terraform import 'module.app.github_actions_secret.cosmos_db_endpoint' "workout-app:COSMOS_DB_ENDPOINT"
terraform import 'module.app.github_actions_variable.cosmos_db_database_name' "workout-app:COSMOS_DB_DATABASE_NAME"
terraform import 'module.app.github_actions_variable.cosmos_db_container_name' "workout-app:COSMOS_DB_CONTAINER_NAME"
terraform import 'module.app.github_actions_variable.static_web_app_name' "workout-app:STATIC_WEB_APP_NAME"
terraform import 'module.app.github_actions_variable.resource_group_name' "workout-app:RESOURCE_GROUP_NAME"
```

## Step 8: Verify Import

```bash
cd workout-app/tofu

# Plan should show no changes (or minimal changes)
terraform plan

# If there are minor changes (tags, descriptions), that's okay
# Apply to synchronize
terraform apply
```

## Step 9: Test Both Repos

```bash
# Test infra repo
cd infra-bootstrap/tofu
terraform plan  # Should show no changes

# Test app repo
cd ../../workout-app/tofu
terraform plan  # Should show no changes

# Verify outputs
terraform output
```

## Alternative: Start Fresh (If Import is Too Complex)

If importing is too complex, you can opt to recreate resources:

1. **Export data**: Backup any data in Cosmos DB
2. **Destroy old resources**: `terraform destroy` in old config
3. **Deploy with module**: Fresh deployment using the module
4. **Restore data**: Import data back to Cosmos DB

**⚠️ Warning**: This causes downtime!

## Troubleshooting

### Import Failed - Resource Not Found
- Double-check resource IDs in Azure Portal
- Ensure you're using the correct subscription ID
- Some resources might have been already removed

### Random String Mismatch
- If the random suffix doesn't match, you can manually set it:
```bash
terraform import 'module.app.random_string.suffix' abc123
```

### Role Assignment Import Issues
- Role assignments can be tricky to import
- You can recreate them (Terraform will update existing assignments)
- Use `terraform apply` and let it manage them

### State Drift Detected
- Some minor differences are okay (tags, descriptions)
- Review carefully and apply if safe
- Major drifts might indicate wrong configuration

## Rollback Plan

If something goes wrong:

```bash
# Restore from backup
cd infra-bootstrap/tofu
terraform state push backup-state-YYYYMMDD-HHMMSS.json

# Or restore from Git
git checkout backup-before-refactor
terraform init
terraform plan
```

## Post-Migration Checklist

- [ ] Infra repo plan shows no changes
- [ ] App repo plan shows no changes
- [ ] Website is accessible at `workout.romaine.life`
- [ ] API is accessible at `api.workout.romaine.life`
- [ ] GitHub Actions runs successfully in app repo
- [ ] Cosmos DB data is intact
- [ ] Email DNS records still work
- [ ] Delete backup branch once confirmed working

## Benefits After Migration

✅ **Separation of Concerns**: Infra and app are independently managed  
✅ **Faster Deployments**: App changes don't affect infra  
✅ **Reusable Pattern**: Easy to deploy new apps  
✅ **Better Organization**: Clear ownership boundaries  
✅ **Safer Operations**: Reduced blast radius of changes

## Support

If you encounter issues during migration:
- Review Terraform error messages carefully
- Check Azure Portal for resource states
- Consult [APP_REPO_SETUP.md](./APP_REPO_SETUP.md) for correct configuration
- File an issue in the infra-bootstrap repository
