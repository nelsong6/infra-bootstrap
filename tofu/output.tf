# ============================================================================
# Shared Infrastructure - Outputs
# ============================================================================
# These outputs are consumed by app repositories via remote state data source.
# App repos reference these values to deploy resources in the shared infrastructure.
# ============================================================================

# ============================================================================
# Resource Group Outputs
# ============================================================================

output "resource_group_name" {
  value       = data.azurerm_resource_group.main.name
  description = "Name of the shared resource group for all applications"
}

output "resource_group_location" {
  value       = data.azurerm_resource_group.main.location
  description = "Azure region where resources are deployed"
}

output "resource_group_id" {
  value       = data.azurerm_resource_group.main.id
  description = "Resource ID of the shared resource group"
}

# ============================================================================
# DNS Zone Outputs
# ============================================================================

output "dns_zone_name" {
  value       = azurerm_dns_zone.main.name
  description = "Name of the shared DNS zone (e.g., romaine.life)"
}

output "dns_zone_id" {
  value       = azurerm_dns_zone.main.id
  description = "Resource ID of the shared DNS zone"
}

output "dns_zone_nameservers" {
  value       = azurerm_dns_zone.main.name_servers
  description = "Azure DNS nameservers for the domain (configure these at your registrar)"
}

# ============================================================================
# Container App Environment Outputs
# ============================================================================

output "container_app_environment_name" {
  value       = azurerm_container_app_environment.main.name
  description = "Name of the shared Container App Environment"
}

output "container_app_environment_id" {
  value       = azurerm_container_app_environment.main.id
  description = "Resource ID of the shared Container App Environment"
}

# ============================================================================
# Cosmos DB Outputs
# ============================================================================

output "cosmos_db_account_name" {
  value       = azurerm_cosmosdb_account.main.name
  description = "Name of the shared Cosmos DB account"
}

output "cosmos_db_account_id" {
  value       = azurerm_cosmosdb_account.main.id
  description = "Resource ID of the shared Cosmos DB account"
}

# ============================================================================
# App Configuration Outputs
# ============================================================================

output "azure_app_config_endpoint" {
  value       = azurerm_app_configuration.main.endpoint
  description = "Endpoint URL for the shared Azure App Configuration store"
}

output "azure_app_config_resource_id" {
  value       = azurerm_app_configuration.main.id
  description = "Resource ID of the shared Azure App Configuration store"
}

# ============================================================================
# Azure Identity Outputs
# ============================================================================

output "azure_subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "Azure subscription ID"
}

output "azure_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure tenant ID"
}
