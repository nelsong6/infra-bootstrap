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

output "arm_subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "Azure subscription ID"
}

output "arm_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Azure tenant ID"
}

# ============================================================================
# Auth0 Outputs
# ============================================================================

output "auth0_domain" {
  value       = auth0_custom_domain.main.domain
  description = "Auth0 custom domain (e.g., auth.romaine.life)"
}

output "auth0_connection_github_id" {
  value       = auth0_connection.github.id
  description = "Auth0 GitHub connection ID"
}

output "auth0_connection_google_id" {
  value       = auth0_connection.google.id
  description = "Auth0 Google connection ID"
}

output "auth0_connection_apple_id" {
  value       = auth0_connection.apple.id
  description = "Auth0 Apple connection ID"
}

# ============================================================================
# Landing Page Outputs
# ============================================================================

output "landing_page_resource_group_name" {
  value       = azurerm_resource_group.landing.name
  description = "Resource group for the landing page Static Web App"
}

output "landing_page_static_web_app_name" {
  value       = azurerm_static_web_app.landing.name
  description = "Name of the landing page Static Web App"
}

