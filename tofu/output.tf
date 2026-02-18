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
  value       = data.azurerm_dns_zone.main.name
  description = "Name of the shared DNS zone (e.g., romaine.life)"
}

output "dns_zone_id" {
  value       = data.azurerm_dns_zone.main.id
  description = "Resource ID of the shared DNS zone"
}

output "dns_zone_nameservers" {
  value       = data.azurerm_dns_zone.main.name_servers
  description = "Azure DNS nameservers for the domain (configure these at your registrar)"
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

# ============================================================================
# Usage Instructions
# ============================================================================

output "usage_instructions" {
  value       = <<-EOT
  
  ====================================================================================================
  Shared Infrastructure - Successfully Deployed
  ====================================================================================================
  
  This infrastructure provides shared resources for all applications:
  
  ✅ Resource Group:  ${data.azurerm_resource_group.main.name}
  ✅ Location:        ${data.azurerm_resource_group.main.location}
  ✅ DNS Zone:        ${data.azurerm_dns_zone.main.name}
  ✅ Nameservers:     ${join(", ", data.azurerm_dns_zone.main.name_servers)}
  
  ====================================================================================================
  Deploying Applications
  ====================================================================================================
  
  To deploy an application, use the azure-app module in your app repository:
  
  1. Create a new app repository (e.g., workout-app, notes-app)
  
  2. Add Terraform configuration referencing this infra state:
  
     data "terraform_remote_state" "infra" {
       backend = "azurerm"
       config = {
         resource_group_name  = "tfstate-rg"
         storage_account_name = "tfstate4807"
         container_name       = "tfstate"
         key                  = "infra.tfstate"
       }
     }
  
  3. Use the azure-app module:
  
     module "my_app" {
       source = "git::https://github.com/nelsong6/infra-bootstrap.git//modules/azure-app?ref=main"
       
       resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
       location            = data.terraform_remote_state.infra.outputs.resource_group_location
       dns_zone_name       = data.terraform_remote_state.infra.outputs.dns_zone_name
       dns_zone_id         = data.terraform_remote_state.infra.outputs.dns_zone_id
       
       app_name                = "myapp"
       custom_domain_subdomain = "myapp"
       github_repo             = "owner/repo"
       container_image         = "ghcr.io/owner/repo/api:latest"
       
       cosmos_db_config = {
         database_name = "MyAppDB"
         containers = [{
           name                = "items"
           partition_key_paths = ["/userId"]
         }]
       }
     }
  
  For detailed documentation, see: modules/azure-app/README.md
  
  ====================================================================================================
  
  EOT
  description = "Instructions for using this shared infrastructure"
}
