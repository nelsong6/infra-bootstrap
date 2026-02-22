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

variable "github_owner" {
  type = string
}

variable "spacelift_space_id" {
  type    = string
  default = "root"
}

resource "github_repository" "this" {
  name       = var.name
  visibility = "private"
  auto_init  = true
}

resource "spacelift_stack" "this" {
  name                    = var.name
  repository              = github_repository.this.name
  namespace               = var.github_owner
  branch                  = "main"
  space_id                = var.spacelift_space_id
  terraform_workflow_tool = "OPEN_TOFU"
}
