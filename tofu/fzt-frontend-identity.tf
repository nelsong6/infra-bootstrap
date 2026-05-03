# ============================================================================
# Per-app workload identity for fzt-frontend
# ============================================================================
# Lives here rather than fzt-frontend/tofu/ because fzt-frontend doesn't
# stand up its own tofu pipeline today. When (if) it grows one, this
# whole file should move into fzt-frontend/tofu/identity.tf to match the
# convention every other migrated app follows.
#
# Scoped to what backend/server.js + config.js call:
#   - Cosmos data on dbs/HomepageDB (the pod queries the
#     fzt-frontend-data container in HomepageDB)
#   - KV Secrets User on api-jwt-signing-secret (the legacy shared JWT
#     secret config.js reads)
#   - App Configuration Data Reader at store level (config.js reads
#     `cosmos_db_endpoint`; the simplest correct grant is Data Reader
#     on the whole store — App Config doesn't have per-key RBAC)
# ============================================================================

resource "azurerm_user_assigned_identity" "fzt_frontend" {
  name                = "fzt-frontend-identity"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_cosmosdb_sql_role_assignment" "fzt_frontend_cosmos" {
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.serverless.name
  role_definition_id  = "${azurerm_cosmosdb_account.serverless.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.fzt_frontend.principal_id
  # `<account>/dbs/<name>` — Cosmos data plane scope, NOT the ARM ID.
  scope = "${azurerm_cosmosdb_account.serverless.id}/dbs/HomepageDB"
}

resource "azurerm_role_assignment" "fzt_frontend_kv_jwt_secret" {
  scope                = "${data.azurerm_key_vault.main.id}/secrets/api-jwt-signing-secret"
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.fzt_frontend.principal_id
}

resource "azurerm_role_assignment" "fzt_frontend_appconfig" {
  scope                = azurerm_app_configuration.main.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_user_assigned_identity.fzt_frontend.principal_id
}

resource "azurerm_federated_identity_credential" "fzt_frontend" {
  name                = "aks-fzt-frontend"
  resource_group_name = data.azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.fzt_frontend.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:fzt-frontend:infra-shared"
}

output "fzt_frontend_identity_client_id" {
  value       = azurerm_user_assigned_identity.fzt_frontend.client_id
  description = "client_id of fzt-frontend-identity. Pin into fzt-frontend/k8s/serviceaccount.yaml."
}
