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

variable "github_dispatch_context_id" {
  type = string
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
  space_id                = "root"
  terraform_workflow_tool = "OPEN_TOFU"
  project_root            = "tofu"
  labels                  = ["azure"]
  lifecycle {
    ignore_changes = [ branch ]
  }
}

data "spacelift_context" "global" {
  context_id = "global"
}

resource "spacelift_context_attachment" "attachment" {
  context_id = data.spacelift_context.global.id
  stack_id   = spacelift_stack.stack.id # Your kill-me stack ID
  priority   = 0
}

resource "spacelift_context_attachment" "dispatch_attachment" {
  context_id = var.github_dispatch_context_id
  stack_id   = spacelift_stack.stack.id
}
