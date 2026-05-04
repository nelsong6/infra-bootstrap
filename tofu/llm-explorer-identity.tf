# ============================================================================
# Per-app workload identity for llm-explorer
# ============================================================================
# Lives here rather than llm-explorer/tofu/ because llm-explorer doesn't
# stand up its own tofu pipeline today (no tofu/ dir in the repo). When
# it grows one, this whole file should move there to match the convention
# every other migrated app follows.
#
# Scoped to what backend/server.js + config.js call:
#   - Cosmos data on dbs/HomepageDB (the pod queries the `userdata`
#     container in HomepageDB, filtered by `type='llm-session'`)
#   - KV Secrets User on api-jwt-signing-secret
#   - App Configuration Data Reader at store level
# ============================================================================

resource "azurerm_user_assigned_identity" "llm_explorer" {
  name                = "llm-explorer-identity"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_cosmosdb_sql_role_assignment" "llm_explorer_cosmos" {
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.serverless.name
  role_definition_id  = "${azurerm_cosmosdb_account.serverless.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.llm_explorer.principal_id
  scope               = "${azurerm_cosmosdb_account.serverless.id}/dbs/HomepageDB"
}

resource "azurerm_role_assignment" "llm_explorer_kv_jwt_secret" {
  scope                = "${data.azurerm_key_vault.main.id}/secrets/api-jwt-signing-secret"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.llm_explorer.principal_id
}

resource "azurerm_role_assignment" "llm_explorer_appconfig" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_user_assigned_identity.llm_explorer.principal_id
}

resource "azurerm_federated_identity_credential" "llm_explorer" {
  count               = local.cluster_uses_dedicated_subscription ? 0 : 1
  name                = "aks-llm-explorer"
  resource_group_name = data.azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.llm_explorer.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main[0].oidc_issuer_url
  subject             = "system:serviceaccount:llm-explorer:infra-shared"
}

resource "azurerm_federated_identity_credential" "cluster_llm_explorer" {
  count               = local.cluster_uses_dedicated_subscription ? 1 : 0
  name                = "aks-cluster-llm-explorer"
  resource_group_name = data.azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.llm_explorer.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.cluster[0].oidc_issuer_url
  subject             = "system:serviceaccount:llm-explorer:infra-shared"
}

output "llm_explorer_identity_client_id" {
  value       = azurerm_user_assigned_identity.llm_explorer.client_id
  description = "client_id of llm-explorer-identity. Pin into llm-explorer/k8s/serviceaccount.yaml."
}
