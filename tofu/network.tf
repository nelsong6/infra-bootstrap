# ============================================================================
# Networking
# ============================================================================
# VNet and subnet for AKS. Address space is intentionally large (/16) to
# leave room for future subnets (Bastion, private endpoints, etc.).
# The AKS subnet uses /22 (1024 addresses) — with Azure CNI Overlay only
# node IPs consume subnet addresses, not pod IPs.
# ============================================================================

resource "azurerm_virtual_network" "main" {
  name                = "infra-vnet"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks_nodes" {
  name                 = "aks-nodes"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/22"]
}
