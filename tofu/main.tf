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
# Shared Database Infrastructure - Cosmos DB
# ============================================================================
# This file contains shared database resources that can be used by applications.
# Individual applications can create their own databases and containers within
# this Cosmos DB account, or reference this account for data storage.
# ============================================================================

# Cosmos DB account is defined in cosmos-serverless.tf. The previous
# provisioned free-tier account (infra-cosmos) was torn down in this commit
# after apps migrated off it.

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
  value                  = azurerm_cosmosdb_account.serverless.endpoint
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

# Storage Blob Data Contributor for Nelson's personal identity (local dev API)
resource "azurerm_role_assignment" "nelson_storage" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "cf57d57d-1411-4f59-b517-e9a8600b140a"
}

locals {
  ci_only_apps = toset(["ambience", "fzt", "fzt-terminal", "fzt-frontend", "fzt-automate", "fzt-browser", "fzt-picker", "fzt-desktop"])

  # Apps deployed on AKS — gives the app SP AcrPush on romainecr (for CI to
  # push images) and wires a federated credential to the shared managed
  # identity for `system:serviceaccount:<app>:infra-shared`. Expand as each
  # app migrates off the shared api onto its own K8s Deployment.
  k8s_apps = toset(["ambience", "investing", "house-hunt", "kill-me", "plant-agent", "fzt-frontend", "my-homepage", "diagrams", "llm-explorer", "tank-operator"])
  app_default_branch = {
    "fzt" = "main"
  }
  app_topics = {
    "fzt-desktop"  = ["fzt-downstream"]
    "fzt-showcase" = ["fzt-downstream"]
    "my-homepage"  = ["fzt-downstream"]
  }
  app_pages_branch = {}
}

resource "random_password" "card_utility_stats_vm_admin" {
  length           = 32
  special          = true
  override_special = "!@#$%^&*-_=+?"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_key_vault_secret" "card_utility_stats_vm_admin_password" {
  name         = "card-utility-stats-vm-admin-password"
  key_vault_id = data.azurerm_key_vault.main.id
  value        = random_password.card_utility_stats_vm_admin.result
}

import {
  to = module.app["fzt"].github_repository.repo
  id = "fzt"
}

# ambience: pre-existing repo created manually during the initial AKS
# bring-up. Bringing into tofu so CI federated creds + AcrPush get managed
# alongside the other k8s_apps.
import {
  to = module.app["ambience"].github_repository.repo
  id = "ambience"
}

# The following repos were created outside infra-bootstrap (fzt-frontend and
# fzt-automate on 2026-04-07 as stubs, fzt-browser on 2026-04-16 during the
# split, fzt-picker pre-split). Import tells tofu they already exist.

import {
  to = module.app["fzt-frontend"].github_repository.repo
  id = "fzt-frontend"
}

import {
  to = module.app["fzt-automate"].github_repository.repo
  id = "fzt-automate"
}

import {
  to = module.app["fzt-browser"].github_repository.repo
  id = "fzt-browser"
}

import {
  to = module.app["fzt-picker"].github_repository.repo
  id = "fzt-picker"
}

# llm-explorer: pre-existing repo on master branch. Needs the full web
# sub-module (not ci_only) since it's an app with a frontend; currently
# local-only but will be deployed as a SWA later.
import {
  to = module.app["llm-explorer"].github_repository.repo
  id = "llm-explorer"
}

import {
  to = module.app["card-utility-stats"].github_repository.repo
  id = "card-utility-stats"
}

moved {
  from = module.app["fuzzy-tiered"]
  to   = module.app["fzt"]
}

moved {
  from = module.app["fuzzy-tiers-showcase"]
  to   = module.app["fzt-showcase"]
}

moved {
  from = module.app["infra-diagram"]
  to   = module.app["diagrams"]
}

module "app" {
  source = "./app"
  for_each = toset([
    "ambience",
    "bender-world",
    "card-utility-stats",
    "diagrams",
    "eight-queens",
    "fzt",
    "fzt-automate",
    "fzt-browser",
    "fzt-desktop",
    "fzt-frontend",
    "fzt-picker",
    "fzt-showcase",
    "fzt-terminal",
    "house-hunt",
    "investing",
    "kill-me",
    "lights",
    "llm-explorer",
    "my-homepage",
    "plant-agent",
    "tank-operator",
  ])

  name                       = each.key
  ci_only                    = contains(local.ci_only_apps, each.key)
  default_branch             = lookup(local.app_default_branch, each.key, "main")
  topics                     = lookup(local.app_topics, each.key, [])
  pages_branch               = lookup(local.app_pages_branch, each.key, "")
  key_vault_name             = data.azurerm_key_vault.main.name
  key_vault_id               = data.azurerm_key_vault.main.id
  app_config_id              = azurerm_app_configuration.main.id
  cosmos_account_id          = azurerm_cosmosdb_account.serverless.id
  cosmos_account_name        = azurerm_cosmosdb_account.serverless.name
  cosmos_resource_group_name = data.azurerm_resource_group.main.name
  arm_tenant_id              = data.azurerm_client_config.current.tenant_id
  arm_subscription_id        = data.azurerm_client_config.current.subscription_id
  google_client_id           = data.azurerm_key_vault_secret.google_oauth_client_id.value
}

