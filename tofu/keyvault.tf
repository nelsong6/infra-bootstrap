# ============================================================================
# Azure Key Vault
# ============================================================================
# Shared Key Vault for storing secrets used across the infrastructure.
# RBAC authorization is used for access control (recommended over access policies).

resource "azurerm_key_vault" "main" {
  name                = "infra-kv-romaine"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

# Grant the service principal running Tofu data-plane access to manage secrets
resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
