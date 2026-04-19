# ============================================================================
# Azure Kubernetes Service (AKS)
# ============================================================================
# Shared AKS cluster replacing Azure Container Apps. Each app gets its own
# Deployment instead of sharing a single always-on API. Ingress replaces SWA.
# ExternalSecrets replaces direct Key Vault references.
#
# Workload identity is enabled so pods can assume managed identities via
# federated credentials (see shared_workload below).
# ============================================================================

resource "azurerm_kubernetes_cluster" "main" {
  name                = "infra-aks"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  dns_prefix          = "infra-aks"

  # Free tier — no SLA, no cost for the control plane
  sku_tier = "Free"

  # Workload identity + OIDC issuer — required for pods to assume
  # managed identities via federated credentials
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Automatic patch upgrades for security fixes
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  # Cluster identity for managing Azure resources (load balancers, disks).
  # Separate from workload identity used by pods.
  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name           = "system"
    vm_size        = "Standard_B2ms"
    node_count     = 1
    os_disk_size_gb = 30
    vnet_subnet_id = azurerm_subnet.aks_nodes.id

    temporary_name_for_rotation = "tmp"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }
}

# ============================================================================
# Workload Identity — Federated Credential for Shared Identity
# ============================================================================
# Bridges the existing infra-shared-identity (which already has Cosmos DB,
# App Config, Key Vault, and Storage roles) to the AKS OIDC issuer.
# Pods using the "infra-shared" service account in the "default" namespace
# can assume this identity to access Azure resources.

resource "azurerm_federated_identity_credential" "shared_workload" {
  name                = "aks-shared-workload"
  resource_group_name = data.azurerm_resource_group.main.name
  parent_id           = azurerm_user_assigned_identity.shared.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:default:infra-shared"
}
