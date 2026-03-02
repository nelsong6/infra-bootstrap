terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~> 1.0"
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

variable "spacelift_space_id" {
  type    = string
  default = "root"
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

resource "github_repository" "repo" {
  name       = var.name
  visibility = "public"
  auto_init  = true

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  delete_branch_on_merge = true
}
resource "spacelift_stack" "stack" {
  name                     = var.name
  repository               = github_repository.repo.name
  branch                   = "main"
  space_id                 = "root"
  terraform_workflow_tool  = "OPEN_TOFU"
  project_root             = "tofu"
  additional_project_globs = [".github/workflows/**", "frontend/**", "backend/**"]
  labels                   = ["azure"]

  before_init = [
    "echo \"Exchanging native Spacelift OIDC token for Azure access token...\"",
    "AZ_TOKEN_RES=$(curl -sS -X POST \"https://login.microsoftonline.com/$ARM_TENANT_ID/oauth2/v2.0/token\" -d \"client_id=$ARM_CLIENT_ID\" -d \"scope=https://vault.azure.net/.default\" -d \"grant_type=client_credentials\" -d \"client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer\" -d \"client_assertion=$SPACELIFT_OIDC_TOKEN\")",
    "if echo \"$AZ_TOKEN_RES\" | grep -q \"error\"; then echo \"❌ Azure Auth Failed: $AZ_TOKEN_RES\"; exit 1; fi",
    "AZ_TOKEN=$(echo \"$AZ_TOKEN_RES\" | jq -r .access_token)",

    "echo \"Fetching GitHub PAT from Key Vault...\"",
    "KV_RES=$(curl -sS \"https://${var.key_vault_name}.vault.azure.net/secrets/github-pat?api-version=7.4\" -H \"Authorization: Bearer $AZ_TOKEN\")",
    "if echo \"$KV_RES\" | grep -q \"error\"; then echo \"❌ Key Vault Fetch Failed: $KV_RES\"; exit 1; fi",

    "export TF_VAR_github_pat=$(echo \"$KV_RES\" | jq -r .value)",
    "export TF_VAR_github_owner=\"$SPACELIFT_VCS_OWNER\"",
    "export ARM_OIDC_TOKEN=\"$SPACELIFT_OIDC_TOKEN\"",

    "echo \"Injecting master provider configurations...\"",
    "curl -f -sS -H \"Authorization: token $TF_VAR_github_pat\" -O -L \"https://raw.githubusercontent.com/nelsong6/infra-bootstrap/main/tofu/provider/shared_providers.tf\"",
    "curl -f -sS -H \"Authorization: token $TF_VAR_github_pat\" -O -L \"https://raw.githubusercontent.com/nelsong6/infra-bootstrap/main/tofu/provider/.terraform.lock.hcl\""
  ]

  after_apply = [
    "echo \"Waking up GitHub Actions CD pipeline...\"",
    "curl --fail-with-body -sS -L -X POST -H \"Accept: application/vnd.github+json\" -H \"Authorization: Bearer $TF_VAR_github_pat\" -H \"X-GitHub-Api-Version: 2022-11-28\" https://api.github.com/repos/${github_repository.repo.full_name}/actions/workflows/full-stack-deploy.yml/dispatches -d '{\"ref\": \"'\"$TF_VAR_spacelift_commit_branch\"'\", \"inputs\": {\"commit_sha\": \"'\"$TF_VAR_spacelift_commit_sha\"'\"}}'"
  ]

  lifecycle {
    ignore_changes = [branch]
  }
}

data "spacelift_current_stack" "this" {}

resource "spacelift_stack_dependency" "infra" {
  stack_id            = spacelift_stack.stack.id
  depends_on_stack_id = data.spacelift_current_stack.this.id
}

resource "spacelift_stack_dependency_reference" "resource_group_name" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "resource_group_name"
  input_name          = "TF_VAR_infra_resource_group_name"
}

resource "spacelift_stack_dependency_reference" "dns_zone_name" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "dns_zone_name"
  input_name          = "TF_VAR_infra_dns_zone_name"
}

resource "spacelift_stack_dependency_reference" "container_app_environment_id" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "container_app_environment_id"
  input_name          = "TF_VAR_infra_container_app_environment_id"
}

resource "spacelift_stack_dependency_reference" "cosmos_db_account_name" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "cosmos_db_account_name"
  input_name          = "TF_VAR_infra_cosmos_db_account_name"
}

resource "spacelift_stack_dependency_reference" "cosmos_db_account_id" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "cosmos_db_account_id"
  input_name          = "TF_VAR_infra_cosmos_db_account_id"
}

resource "spacelift_stack_dependency_reference" "azure_app_config_endpoint" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "azure_app_config_endpoint"
  input_name          = "TF_VAR_infra_azure_app_config_endpoint"
}

resource "spacelift_stack_dependency_reference" "azure_app_config_resource_id" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "azure_app_config_resource_id"
  input_name          = "TF_VAR_infra_azure_app_config_resource_id"
}

resource "spacelift_stack_dependency_reference" "auth0_domain" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "auth0_domain"
  input_name          = "TF_VAR_infra_auth0_domain"
}

resource "spacelift_stack_dependency_reference" "auth0_connection_github_id" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "auth0_connection_github_id"
  input_name          = "TF_VAR_infra_auth0_connection_github_id"
}

resource "spacelift_stack_dependency_reference" "auth0_connection_google_id" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "auth0_connection_google_id"
  input_name          = "TF_VAR_infra_auth0_connection_google_id"
}

resource "spacelift_stack_dependency_reference" "auth0_connection_apple_id" {
  stack_dependency_id = spacelift_stack_dependency.infra.id
  output_name         = "auth0_connection_apple_id"
  input_name          = "TF_VAR_infra_auth0_connection_apple_id"
}

data "spacelift_context" "global" {
  context_id = "global"
}

resource "spacelift_context_attachment" "global" {
  context_id = data.spacelift_context.global.id
  stack_id   = spacelift_stack.stack.id
  priority   = 0
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

