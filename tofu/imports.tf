import {
  to = module.app["house-hunt"].github_repository.repo
  id = "house-hunt"
}

import {
  to = module.app["fzt-terminal"].github_repository.repo
  id = "fzt-terminal"
}

import {
  provider = azurerm.romaine_life
  to       = azurerm_role_assignment.romaine_life_network_contributor
  id       = "/subscriptions/606a1ca1-5833-4d21-8937-d0fcd97cd0a0/resourceGroups/rg-card-utility-stats-dev/providers/Microsoft.Authorization/roleAssignments/35de7377-112c-4521-91bf-98a1490e6180"
}

import {
  to = azurerm_virtual_network_peering.infra_to_romaine_life_card_utility_stats_dev
  id = "/subscriptions/aee0cbd2-8074-4001-b610-0f8edb4eaa3c/resourceGroups/infra/providers/Microsoft.Network/virtualNetworks/infra-vnet/virtualNetworkPeerings/infra-vnet-to-card-utility-stats-dev"
}

import {
  provider = azurerm.romaine_life
  to       = azurerm_virtual_network_peering.romaine_life_card_utility_stats_dev_to_infra
  id       = "/subscriptions/606a1ca1-5833-4d21-8937-d0fcd97cd0a0/resourceGroups/rg-card-utility-stats-dev/providers/Microsoft.Network/virtualNetworks/vnet-card-utility-stats-dev/virtualNetworkPeerings/card-utility-stats-dev-to-infra-vnet"
}
