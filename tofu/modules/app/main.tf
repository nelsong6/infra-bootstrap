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
  project_root = "tofu"
  labels = ["azure"]
}

data "spacelift_current_stack" "this" {}

# 1. Establish the dependency link between the stacks
resource "spacelift_stack_dependency" "dependency" {
  # Assuming your spacelift_stack resource is named 'kill_me' or 'repo'
  stack_id            = spacelift_stack.stack.id 
  depends_on_stack_id = data.spacelift_current_stack.this.id
}

# 2. Define the list of outputs you want to share
locals {
  kill_me_inputs = [
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
}

# 3. Loop through the list to create the references dynamically
resource "spacelift_stack_dependency_reference" "reference" {
  for_each = toset(local.kill_me_inputs)

  stack_dependency_id = spacelift_stack_dependency.dependency.id
  output_name         = each.value
  input_name          = "TF_VAR_${each.value}"
}
