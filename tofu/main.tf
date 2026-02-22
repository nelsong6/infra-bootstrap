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

# This tells Spacelift to trust GitHub's token authority
resource "spacelift_oidc_provider" "github_actions" {
  name     = "GitHub Actions"
  issuer   = "https://token.actions.githubusercontent.com"
  
  # The audience is what GitHub puts in the token to prove it's meant for Spacelift
  audiences = ["spacelift"]
}
