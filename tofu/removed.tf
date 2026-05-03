# The romaine-life subscription and card-utility-stats dev VNet were deleted
# after the Slay the Spire image-building experiment was abandoned. Forget the
# old cross-subscription peering objects without trying to call the deleted
# subscription during plan/apply.

removed {
  from = azurerm_role_assignment.romaine_life_network_contributor

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_virtual_network_peering.infra_to_romaine_life_card_utility_stats_dev

  lifecycle {
    destroy = false
  }
}

removed {
  from = azurerm_virtual_network_peering.romaine_life_card_utility_stats_dev_to_infra

  lifecycle {
    destroy = false
  }
}
