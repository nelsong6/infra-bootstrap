# ============================================================================
# Azure App Module - Outputs
# ============================================================================

# Resource Group
output "resource_group_name" {
  value       = var.resource_group_name
  description = "Name of the resource group"
}

# Static Web App (Frontend)
output "static_web_app_id" {
  value       = azurerm_static_web_app.frontend.id
  description = "Resource ID of the Static Web App"
}

output "static_web_app_name" {
  value       = azurerm_static_web_app.frontend.name
  description = "Name of the Static Web App"
}

output "static_web_app_default_hostname" {
  value       = azurerm_static_web_app.frontend.default_host_name
  description = "Default Azure hostname of the Static Web App"
}

output "static_web_app_url" {
  value       = "https://${azurerm_static_web_app.frontend.default_host_name}"
  description = "Default URL of the Static Web App"
}

output "static_web_app_custom_domain_url" {
  value       = "https://${local.frontend_domain}"
  description = "Custom domain URL of the Static Web App"
}

# Cosmos DB
output "cosmos_db_account_id" {
  value       = azurerm_cosmosdb_account.main.id
  description = "Resource ID of the Cosmos DB account"
}

output "cosmos_db_account_name" {
  value       = azurerm_cosmosdb_account.main.name
  description = "Name of the Cosmos DB account"
}

output "cosmos_db_endpoint" {
  value       = azurerm_cosmosdb_account.main.endpoint
  description = "Cosmos DB account endpoint"
}

output "cosmos_db_database_name" {
  value       = azurerm_cosmosdb_sql_database.main.name
  description = "Name of the Cosmos DB database"
}

output "cosmos_db_container_names" {
  value       = [for container in azurerm_cosmosdb_sql_container.containers : container.name]
  description = "Names of Cosmos DB containers"
}

# Container Apps (Backend)
output "container_app_environment_id" {
  value       = azurerm_container_app_environment.main.id
  description = "Resource ID of the Container App Environment"
}

output "container_app_id" {
  value       = azurerm_container_app.api.id
  description = "Resource ID of the Container App"
}

output "container_app_name" {
  value       = azurerm_container_app.api.name
  description = "Name of the Container App"
}

output "container_app_fqdn" {
  value       = azurerm_container_app.api.ingress[0].fqdn
  description = "Default Azure FQDN of the Container App"
}

output "container_app_url" {
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
  description = "Default URL of the Container App backend API"
}

output "container_app_custom_domain_url" {
  value       = "https://${local.backend_domain}"
  description = "Custom domain URL of the Container App backend API"
}

output "container_app_identity_principal_id" {
  value       = azurerm_container_app.api.identity[0].principal_id
  description = "Principal ID of the Container App managed identity"
}

# DNS
output "frontend_custom_domain" {
  value       = local.frontend_domain
  description = "Frontend custom domain"
}

output "backend_custom_domain" {
  value       = local.backend_domain
  description = "Backend API custom domain"
}

# Summary
output "deployment_summary" {
  value = {
    app_name     = var.app_name
    environment  = var.environment
    frontend_url = "https://${local.frontend_domain}"
    backend_url  = "https://${local.backend_domain}"
    github_repo  = var.github_repo
  }
  description = "Summary of the deployed application"
}
