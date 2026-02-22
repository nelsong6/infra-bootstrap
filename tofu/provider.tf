terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "~> 1.40.0" 
    }
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~> 1.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

provider "azuread" {
  use_oidc = true
}

variable "auth0_client_secret" {
  type      = string
  sensitive = true
}

data "spacelift_current_stack" "this" {}

provider "github" {
  owner = var.github_owner
  token = var.spacelift_vcs_app_token
}

provider "auth0" {
  domain        = "dev-gtdi5x5p0nmticqd.us.auth0.com"
  client_id     = "7qsN7zrBAh7TwhjEUcgtU46yOSs9TXbg"
  client_secret = var.auth0_client_secret
}
