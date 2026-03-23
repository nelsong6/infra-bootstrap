terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

variable "name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "app_config_id" {
  type = string
}

variable "cosmos_account_id" {
  type = string
}

variable "cosmos_account_name" {
  type = string
}

variable "cosmos_resource_group_name" {
  type = string
}

variable "arm_tenant_id" {
  type = string
}

variable "arm_subscription_id" {
  type = string
}

variable "google_client_id" {
  type = string
}


resource "github_repository" "repo" {
  name       = var.name
  visibility = "public"
  auto_init  = true

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  delete_branch_on_merge = true
}

# Per-app Azure AD application + service principal
resource "azuread_application" "app" {
  display_name = var.name
}

resource "azuread_service_principal" "app" {
  client_id = azuread_application.app.client_id
}

resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${var.arm_subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.app.object_id
}

resource "azurerm_role_assignment" "rbac_admin" {
  scope                = "/subscriptions/${var.arm_subscription_id}"
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.app.object_id
}

resource "azurerm_role_assignment" "keyvault_secrets_officer" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.app.object_id
}

resource "azurerm_role_assignment" "appconfig_data_owner" {
  scope                = var.app_config_id
  role_definition_name = "App Configuration Data Owner"
  principal_id         = azuread_service_principal.app.object_id
}

resource "azurerm_role_assignment" "storage_blob_reader" {
  scope                = "/subscriptions/${var.arm_subscription_id}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.app.object_id
}

# Cosmos DB Built-in Data Reader — allows snapshot generation in CI
resource "azurerm_cosmosdb_sql_role_assignment" "cosmos_data_reader" {
  resource_group_name = var.cosmos_resource_group_name
  account_name        = var.cosmos_account_name
  role_definition_id  = "${var.cosmos_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000001"
  principal_id        = azuread_service_principal.app.object_id
  scope               = var.cosmos_account_id
}

# Grant SP permission to manage its own Azure AD app registration (e.g. redirect URIs).
# Application.ReadWrite.OwnedBy app role from Microsoft Graph.
data "azuread_service_principal" "msgraph" {
  client_id = "00000003-0000-0000-c000-000000000000"
}

resource "azuread_app_role_assignment" "app_readwrite_owned" {
  app_role_id         = "18a4783c-866b-4cc7-a460-3d5e5662c884"
  principal_object_id = azuread_service_principal.app.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "github_actions_variable" "key_vault_name" {
  repository    = github_repository.repo.name
  variable_name = "KEY_VAULT_NAME"
  value         = var.key_vault_name
}

resource "github_actions_variable" "arm_client_id" {
  repository    = github_repository.repo.name
  variable_name = "ARM_CLIENT_ID"
  value         = azuread_application.app.client_id
}

resource "github_actions_variable" "arm_tenant_id" {
  repository    = github_repository.repo.name
  variable_name = "ARM_TENANT_ID"
  value         = var.arm_tenant_id
}

resource "github_actions_variable" "arm_subscription_id" {
  repository    = github_repository.repo.name
  variable_name = "ARM_SUBSCRIPTION_ID"
  value         = var.arm_subscription_id
}

resource "azuread_application_federated_identity_credential" "github_actions_main" {
  application_id = azuread_application.app.id
  display_name   = "${var.name}-github-actions-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${github_repository.repo.full_name}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "github_actions_prod" {
  application_id = azuread_application.app.id
  display_name   = "${var.name}-github-actions-prod"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${github_repository.repo.full_name}:environment:prod"
}

resource "azuread_application_federated_identity_credential" "github_actions_pr" {
  application_id = azuread_application.app.id
  display_name   = "${var.name}-github-actions-pr"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${github_repository.repo.full_name}:pull_request"
}

resource "github_actions_variable" "tfstate_storage_account" {
  repository    = github_repository.repo.name
  variable_name = "TFSTATE_STORAGE_ACCOUNT"
  value         = "nelsontofu"
}

resource "github_actions_variable" "google_client_id" {
  repository    = github_repository.repo.name
  variable_name = "GOOGLE_CLIENT_ID"
  value         = var.google_client_id
}

