# ============================================================================
# Azure Container Registry (ACR)
# ============================================================================
# Shared container registry for all app images. AKS pulls images via the
# kubelet identity's AcrPull role — no image pull secrets needed.
# ============================================================================

resource "azurerm_container_registry" "main" {
  name                = "romainecr"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
}

# Grant AcrPull to the AKS kubelet identity so nodes can pull images
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = local.cluster_uses_dedicated_subscription ? 0 : 1
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main[0].kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "cluster_aks_acr_pull" {
  count                = local.cluster_uses_dedicated_subscription ? 1 : 0
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.cluster[0].kubelet_identity[0].object_id
}

# AcrPush for each k8s-migrated app's service principal. CI uses the SP (via
# OIDC) to `az acr login` and `docker push` its image during build-and-deploy.
# Subscription-scoped Contributor doesn't cover dataActions, so AcrPush must
# be granted explicitly.
resource "azurerm_role_assignment" "app_acr_push" {
  for_each             = local.k8s_apps
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = module.app[each.key].service_principal_object_id
}
