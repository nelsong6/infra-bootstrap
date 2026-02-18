terraform {
  backend "azurerm" {
    resource_group_name  = "infra"
    storage_account_name = "tfstate9790"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }
}
