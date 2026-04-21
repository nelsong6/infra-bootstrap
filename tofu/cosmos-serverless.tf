# ============================================================================
# New serverless Cosmos DB account (replacing infra-cosmos)
# ============================================================================
# The existing `infra-cosmos` account is provisioned Standard with free tier
# enabled. That model made sense when the plan was one shared-throughput DB,
# but the app tofus ended up with no throughput declared, so Azure defaulted
# every container to a dedicated 400 RU/s offer. Twelve dedicated offers ran
# the bill up to ~$100/mo for essentially idle personal apps.
#
# Serverless is a better fit: pay-per-request, no idle floor, no per-container
# cost. Serverless is mutually exclusive with both free tier and provisioned
# throughput, so a new account is required (accounts cannot be converted
# in-place between the two offer flavours).
#
# During migration both accounts live side by side. The `shared_identity`
# principal gets data-contributor on both, and `cosmos_db_endpoint` in App
# Configuration still points at the old account. Data copy runs, then App
# Config flips, then the old account is torn out.

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

# Surface the new endpoint as its own App Config key so the migration script
# can read both endpoints from one place. `cosmos_db_endpoint` (unqualified)
# stays pointed at the old account until apps are verified on the new one.
resource "azurerm_app_configuration_key" "cosmos_db_endpoint_serverless" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "cosmos_db_endpoint_serverless"
  value                  = azurerm_cosmosdb_account.serverless.endpoint
}
