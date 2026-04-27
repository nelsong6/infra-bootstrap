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
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    azapi = {
      source = "azure/azapi"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "infra"
    storage_account_name = "nelsontofu"
    container_name       = "tfstate"
    key                  = "infra-bootstrap.tfstate"
    use_oidc             = true
  }
}

provider "azurerm" {
  features {}
  use_oidc = true
}

provider "azurerm" {
  alias = "romaine_life"
  features {}
  use_oidc        = true
  subscription_id = "606a1ca1-5833-4d21-8937-d0fcd97cd0a0"
}

provider "azuread" {
  use_oidc = true
}

provider "github" {
  owner = var.github_owner
  token = var.github_pat
}

provider "auth0" {
  domain        = "dev-gtdi5x5p0nmticqd.us.auth0.com"
  client_id     = "7qsN7zrBAh7TwhjEUcgtU46yOSs9TXbg"
  client_secret = data.azurerm_key_vault_secret.auth0_client_secret.value
}
