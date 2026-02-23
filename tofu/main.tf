# ============================================================================
# Shared Infrastructure - Core Resources
# ============================================================================
# This file contains only shared infrastructure resources that are used
# across multiple applications. App-specific resources should use the
# azure-app module in their respective repositories.
# ============================================================================

# Resource Group
# ============================================================================
# The resource group is created by bootstrap.ps1 and referenced here as data
# source. This allows the bootstrap process to manage the RG lifecycle while
# Terraform can use it for deploying resources.

data "azurerm_resource_group" "main" {
  name = "infra"
}

# ============================================================================
# Azure Container App Environment
# ============================================================================
# Shared container app environment for hosting containerized applications.
# Individual apps deploy their container apps into this shared environment.

resource "azurerm_container_app_environment" "main" {
  name                = "infra-aca"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

}

# ============================================================================
# Shared Database Infrastructure - Cosmos DB
# ============================================================================
# This file contains shared database resources that can be used by applications.
# Individual applications can create their own databases and containers within
# this Cosmos DB account, or reference this account for data storage.
# ============================================================================

# Azure Cosmos DB Account
# ============================================================================
# Free tier enabled (400 RU/s and 25 GB storage free)
# Applications can create their own databases within this account

resource "azurerm_cosmosdb_account" "main" {
  name                = "infra-cosmos"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # Enable Free Tier (400 RU/s and 25 GB storage free)
  # NOTE: Free Tier and Serverless are mutually exclusive
  # NOTE: Only one free tier account allowed per subscription
  free_tier_enabled = true

  # Enable automatic failover
  automatic_failover_enabled = false

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = data.azurerm_resource_group.main.location
    failover_priority = 0
  }

}

# ============================================================================
# Azure App Configuration
# ============================================================================
# Shared App Configuration store for centralised key/value settings consumed
# by all applications.  Other stacks discover the store via the infra_vars
# Spacelift context variables (app_config_name / app_config_endpoint).

resource "azurerm_app_configuration" "main" {
  name                = "infra-appconfig"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "free"
}

resource "azurerm_app_configuration_key" "cosmos_db_endpoint" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "cosmos_db_endpoint"
  value                  = azurerm_cosmosdb_account.main.endpoint
}

resource "azurerm_app_configuration_key" "auth0_domain" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "AUTH0_DOMAIN"
  value                  = auth0_custom_domain.main.domain
}

resource "azurerm_app_configuration_key" "auth0_audience" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "AUTH0_AUDIENCE"
  value                  = "https://api.${azurerm_dns_zone.main.name}" # The identifier you used in backend.tf
}

locals {
  apps = toset(["kill-me"])

  infra_vars = {
    resource_group_name            = data.azurerm_resource_group.main.name
    resource_group_location        = data.azurerm_resource_group.main.location
    resource_group_id              = data.azurerm_resource_group.main.id
    dns_zone_name                  = azurerm_dns_zone.main.name
    dns_zone_id                    = azurerm_dns_zone.main.id
    dns_zone_nameservers           = join(",", azurerm_dns_zone.main.name_servers)
    container_app_environment_name = azurerm_container_app_environment.main.name
    container_app_environment_id   = azurerm_container_app_environment.main.id
    cosmos_db_account_name         = azurerm_cosmosdb_account.main.name
    cosmos_db_account_id           = azurerm_cosmosdb_account.main.id
    azure_app_config_endpoint      = azurerm_app_configuration.main.endpoint
    azure_app_config_resource_id   = azurerm_app_configuration.main.id
    azure_subscription_id          = data.azurerm_client_config.current.subscription_id
    azure_tenant_id                = data.azurerm_client_config.current.tenant_id
  }
}

data "spacelift_context" "global" {
  context_id = "global"
}

resource "spacelift_environment_variable" "infra_vars" {
  for_each = local.infra_vars

  context_id = data.spacelift_context.global.id
  name       = "TF_VAR_${each.key}"
  value      = each.value
  write_only = false
}

module "app" {
  source   = "./app"
  for_each = local.apps

  name               = each.value
  spacelift_space_id = "root"
  key_vault_name     = azurerm_key_vault.main.name
}

resource "spacelift_policy" "github_actions_oidc" {
  name        = "GitHub Actions OIDC Login"
  description = "Allows GitHub Actions to authenticate via OIDC to read stack outputs"
  type        = "LOGIN"

  # Attaching it to the same space as your stacks
  space_id = "root"

  body = <<-EOF
  package spacelift

  # 1. Grant Read-Only access to the space for any GitHub Action in your personal account.
  # This is exactly what the kill-me repo needs to run 'spacectl stack output'.
  space_read[space_id] {
    space_id := "root"
    input.session.type == "oidc"
    input.session.oidc.iss == "https://token.actions.githubusercontent.com"
    startswith(input.session.oidc.sub, "repo:nelsong6/")
  }

  # 2. Grant Admin access to the space ONLY for the infra-bootstrap main branch.
  # This prevents random feature branches or app repos from altering Spacelift configurations.
  space_admin[space_id] {
    space_id := "root"
    input.session.type == "oidc"
    input.session.oidc.iss == "https://token.actions.githubusercontent.com"
    input.session.oidc.sub == "repo:nelsong6/infra-bootstrap:ref:refs/heads/main"
  }
  EOF
}

