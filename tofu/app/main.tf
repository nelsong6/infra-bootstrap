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
  }
}

variable "name" {
  type = string
}

variable "key_vault_name" {
  type = string
}

variable "arm_client_id" {
  type = string
}

variable "arm_tenant_id" {
  type = string
}

variable "arm_subscription_id" {
  type = string
}

variable "has_backend" {
  description = "Whether the app has a backend (Container App + Cosmos DB + App Configuration)"
  type        = bool
  default     = true
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

resource "github_actions_variable" "key_vault_name" {
  repository    = github_repository.repo.name
  variable_name = "KEY_VAULT_NAME"
  value         = var.key_vault_name
}

resource "github_actions_variable" "arm_client_id" {
  repository    = github_repository.repo.name
  variable_name = "ARM_CLIENT_ID"
  value         = var.arm_client_id
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

data "azuread_application" "global" {
  client_id = var.arm_client_id
}

resource "azuread_application_federated_identity_credential" "github_actions_main" {
  application_id = data.azuread_application.global.id
  display_name   = "${var.name}-github-actions-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${github_repository.repo.full_name}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "github_actions_prod" {
  application_id = data.azuread_application.global.id
  display_name   = "${var.name}-github-actions-prod"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${github_repository.repo.full_name}:environment:prod"
}

resource "azuread_application_federated_identity_credential" "github_actions_pr" {
  application_id = data.azuread_application.global.id
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
