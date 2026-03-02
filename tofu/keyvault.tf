# ============================================================================
# Azure Key Vault (data source)
# ============================================================================
# The Key Vault is created by the bootstrap script (06-keyvault.ps1) and
# referenced here as a data source — the same pattern used for the resource
# group. RBAC authorization is used for access control.

data "azurerm_key_vault" "main" {
  name                = "romaine-kv"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_key_vault_secret" "auth0_client_secret" {
  name         = "auth0-client-secret"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "github_pat" {
  name         = "github-pat"
  key_vault_id = data.azurerm_key_vault.main.id
}
