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
  }
}

variable "name" {
  type = string
}

variable "spacelift_space_id" {
  type    = string
  default = "root"
}

resource "github_repository" "repo" {
  name       = var.name
  visibility = "private"
  auto_init  = true
}

resource "spacelift_stack" "stack" {
  name                    = var.name
  repository              = github_repository.repo.name
  branch                  = "main"
  space_id                = var.spacelift_space_id
  terraform_workflow_tool = "OPEN_TOFU"
  project_root            = "tofu"
  labels                  = ["azure"]
}

data "spacelift_current_stack" "this" {}

resource "spacelift_stack_dependency" "dependency" {
  stack_id            = spacelift_stack.stack.id
  depends_on_stack_id = data.spacelift_current_stack.this.id
}

data "spacelift_context" "global" {
  context_id = "global"
}

resource "spacelift_environment_variable" "infra_vars" {
  for_each = toset(
    [
      "resource_group_name",
      "resource_group_location",
      "resource_group_id",
      "dns_zone_name",
      "dns_zone_id",
      "dns_zone_nameservers",
      "container_app_environment_name",
      "container_app_environment_id",
      "cosmos_db_account_name",
      "cosmos_db_account_id",
      "cosmos_db_endpoint",
      "azure_subscription_id",
      "azure_tenant_id"
    ]
  )

  context_id = data.spacelift_context.global.id
  name       = "TF_VAR_${each.value}"
  value      = nonsensitive(output[each.value].value)
  write_only = false
}

resource "spacelift_context_attachment" "attachment" {
  context_id = data.spacelift_context.global.id
  stack_id   = spacelift_stack.stack.id # Your kill-me stack ID
  priority   = 0
}
