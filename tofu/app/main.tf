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
  space_id                = "root"
  terraform_workflow_tool = "OPEN_TOFU"
  project_root            = "tofu"
  labels                  = ["azure"]
  after_apply = [
    <<-EOF
    echo "Waking up GitHub Actions CD pipeline..."
    curl -L \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $TF_VAR_github_pat" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      https://api.github.com/repos/nelsong6/$SPACELIFT_REPOSITORY/dispatches \
      -d '{"event_type": "spacelift_infra_ready", "client_payload": {"commit_sha": "'"$SPACELIFT_COMMIT_SHA"'"}}'
    EOF
  ]
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
