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
  }

  backend "azurerm" {
    resource_group_name  = "infra"
    storage_account_name = "tfstate6792"
    container_name       = "tfstate"
    key                  = "infra.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true # Enable OIDC authentication
}

provider "azuread" {
  use_oidc = true # Enable OIDC authentication
}

provider "auth0" {
  domain        = ""
  client_id     = ""
  client_secret = var.auth0_admin_client_secret
}
