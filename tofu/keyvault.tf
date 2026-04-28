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

# Azure config for ExternalDNS workload identity — stored as a JSON
# blob so ExternalSecret can sync it as the azure.json file.
resource "azurerm_key_vault_secret" "external_dns_azure_config" {
  name         = "external-dns-azure-config"
  key_vault_id = data.azurerm_key_vault.main.id
  value = jsonencode({
    tenantId                     = data.azurerm_client_config.current.tenant_id
    subscriptionId               = data.azurerm_client_config.current.subscription_id
    resourceGroup                = data.azurerm_resource_group.main.name
    useWorkloadIdentityExtension = true
  })
}

data "azurerm_key_vault_secret" "auth0_client_secret" {
  name         = "auth0-client-secret"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "github_pat" {
  name         = "github-pat"
  key_vault_id = data.azurerm_key_vault.main.id
}
