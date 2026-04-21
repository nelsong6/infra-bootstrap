# ============================================================================
# Shared serverless Cosmos DB account
# ============================================================================
# Replaces the previous provisioned free-tier `infra-cosmos` account (torn
# down 2026-04-20). The old account had apps' tofus declaring DBs with no
# throughput specified, which caused Azure to default every container to a
# dedicated 400 RU/s offer — twelve idle offers ran the bill to ~$100/mo.
#
# Serverless fits the actual usage pattern: pay-per-request, no idle floor,
# no per-container cost. It is mutually exclusive with free tier and with
# provisioned throughput at any scope, so a new account was required —
# accounts cannot be converted in-place between the offer flavours.

resource "azurerm_cosmosdb_account" "serverless" {
  name                = "infra-cosmos-serverless"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # Serverless capability — mutually exclusive with free tier and with
  # provisioned throughput at database/container scope.
  capabilities {
    name = "EnableServerless"
  }

  free_tier_enabled          = false
  automatic_failover_enabled = false

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = data.azurerm_resource_group.main.location
    failover_priority = 0
  }
}

# Cosmos DB Built-in Data Contributor — apps authenticate as the shared
# managed identity and need read/write on the new account during migration
# and after the App Config flip.
resource "azurerm_cosmosdb_sql_role_assignment" "shared_identity_cosmos_serverless" {
  resource_group_name = data.azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.serverless.name
  role_definition_id  = "${azurerm_cosmosdb_account.serverless.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_user_assigned_identity.shared.principal_id
  scope               = azurerm_cosmosdb_account.serverless.id
}

