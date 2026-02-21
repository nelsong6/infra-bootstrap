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
  use_oidc = true
}

provider "azuread" {
  use_oidc = true
}

provider "infisical" {
  host = "https://app.infisical.com"
  auth = {
    oidc = {
      identity_id                     = "474b7b4f-9205-48f6-8ae1-2f4f2a248af1"
      token_environment_variable_name = "GITHUB_OIDC_TOKEN" 
    }
  }
}

ephemeral "infisical_secret" "auth0_secret" {
  name         = "auth0"
  env_slug     = "prod"
  folder_path  = "/"
  workspace_id = "a5846fc0-c6e3-4a47-9deb-b3c6e2da9240"
}

provider "auth0" {
  domain        = "dev-gtdi5x5p0nmticqd.us.auth0.com"
  client_id     = "7qsN7zrBAh7TwhjEUcgtU46yOSs9TXbg"
  client_secret = ephemeral.infisical_secret.auth0_secret.value
}
