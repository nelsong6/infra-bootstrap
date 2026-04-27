# ============================================================================
# Cross-Subscription Networking
# ============================================================================
# Peer the shared infra VNet with the card-utility-stats dev VNet hosted in
# the romaine-life subscription so AKS workloads can reach the VM privately.
# The GitHub Actions OIDC principal needs Network Contributor on the remote
# resource group to manage the far-side peering.
# ============================================================================

locals {
  romaine_life_card_utility_stats_dev = {
    resource_group  = "rg-card-utility-stats-dev"
    virtual_network = "vnet-card-utility-stats-dev"
    local_peering   = "infra-vnet-to-card-utility-stats-dev"
    remote_peering  = "card-utility-stats-dev-to-infra-vnet"
  }
}

data "azurerm_resource_group" "romaine_life_card_utility_stats_dev" {
  provider = azurerm.romaine_life
  name     = local.romaine_life_card_utility_stats_dev.resource_group
}

data "azurerm_virtual_network" "romaine_life_card_utility_stats_dev" {
  provider            = azurerm.romaine_life
  name                = local.romaine_life_card_utility_stats_dev.virtual_network
  resource_group_name = data.azurerm_resource_group.romaine_life_card_utility_stats_dev.name
}

resource "azurerm_role_assignment" "romaine_life_network_contributor" {
  provider             = azurerm.romaine_life
  scope                = data.azurerm_resource_group.romaine_life_card_utility_stats_dev.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_virtual_network_peering" "infra_to_romaine_life_card_utility_stats_dev" {
  name                         = local.romaine_life_card_utility_stats_dev.local_peering
  resource_group_name          = data.azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.main.name
  remote_virtual_network_id    = data.azurerm_virtual_network.romaine_life_card_utility_stats_dev.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "romaine_life_card_utility_stats_dev_to_infra" {
  provider                     = azurerm.romaine_life
  name                         = local.romaine_life_card_utility_stats_dev.remote_peering
  resource_group_name          = data.azurerm_resource_group.romaine_life_card_utility_stats_dev.name
  virtual_network_name         = data.azurerm_virtual_network.romaine_life_card_utility_stats_dev.name
  remote_virtual_network_id    = azurerm_virtual_network.main.id
  allow_virtual_network_access = true

  depends_on = [azurerm_role_assignment.romaine_life_network_contributor]
}
