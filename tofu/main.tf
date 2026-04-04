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
# by all applications.  Other stacks discover the store via
# terraform_remote_state outputs.

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

# ============================================================================
# Shared User-Assigned Managed Identity
# ============================================================================
# Pre-configured identity that apps attach to their Container Apps.
# Common roles are assigned here so app SPs don't need User Access
# Administrator to create role assignments at deploy time.

resource "azurerm_user_assigned_identity" "shared" {
  name                = "infra-shared-identity"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

# Cosmos DB Built-in Data Contributor
resource "azurerm_cosmosdb_sql_role_assignment" "shared_identity_cosmos" {
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  role_definition_id  = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.shared.principal_id
  scope               = azurerm_cosmosdb_account.main.id
}

# App Configuration Data Reader
resource "azurerm_role_assignment" "shared_identity_appconfig" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_user_assigned_identity.shared.principal_id
}

# Key Vault Secrets User
resource "azurerm_role_assignment" "shared_identity_keyvault" {
  scope                = data.azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.shared.principal_id
}

# Storage Blob Data Contributor (subscription scope — covers any app's storage)
resource "azurerm_role_assignment" "shared_identity_storage" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.shared.principal_id
}

locals {
  ci_only_apps = toset(["fuzzy-tiered"])
  app_default_branch = {
    "fuzzy-tiered" = "master"
  }
}

import {
  to = module.app["fuzzy-tiered"].github_repository.repo
  id = "fuzzy-tiered"
}

module "app" {
  source   = "./app"
  for_each = toset([
    "api",
    "bender-world",
    "eight-queens",
    "fuzzy-tiered",
    "fuzzy-tiers-showcase",
    "infra-diagram",
    "investing",
    "kill-me",
    "lights",
    "my-homepage",
    "plant-agent",
  ])

  name                       = each.key
  ci_only                    = contains(local.ci_only_apps, each.key)
  default_branch             = lookup(local.app_default_branch, each.key, "main")
  key_vault_name             = data.azurerm_key_vault.main.name
  key_vault_id               = data.azurerm_key_vault.main.id
  app_config_id              = azurerm_app_configuration.main.id
  cosmos_account_id          = azurerm_cosmosdb_account.main.id
  cosmos_account_name        = azurerm_cosmosdb_account.main.name
  cosmos_resource_group_name = data.azurerm_resource_group.main.name
  arm_tenant_id              = data.azurerm_client_config.current.tenant_id
  arm_subscription_id        = data.azurerm_client_config.current.subscription_id
  google_client_id           = data.azurerm_key_vault_secret.google_oauth_client_id.value
}

