# ============================================================================
# Azure App Module - Variables
# ============================================================================
# This module provides a reusable pattern for deploying Azure-based applications
# with Static Web App (frontend), Cosmos DB (database), and Container Apps (backend)
# ============================================================================

variable "app_name" {
  description = "Name of the application (e.g., 'workout', 'notes'). Used as prefix for resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the Azure resource group (from infra remote state)"
  type        = string
}

variable "location" {
  description = "Azure region (from infra remote state)"
  type        = string
}

variable "dns_zone_name" {
  description = "DNS zone name (e.g., 'romaine.life') from infra remote state"
  type        = string
}

variable "dns_zone_id" {
  description = "DNS zone resource ID from infra remote state"
  type        = string
}

variable "custom_domain_subdomain" {
  description = "Subdomain for custom domain (e.g., 'workout' for workout.romaine.life)"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in format: owner/repo (e.g., 'nelsong6/workout-app')"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch for OIDC subject claim"
  type        = string
  default     = "main"
}

variable "container_image" {
  description = "Container image for backend API (e.g., 'ghcr.io/nelsong6/workout-app/api:latest')"
  type        = string
}

variable "container_cpu" {
  description = "CPU allocation for container (in cores)"
  type        = number
  default     = 0.25
}

variable "container_memory" {
  description = "Memory allocation for container (e.g., '0.5Gi')"
  type        = string
  default     = "0.5Gi"
}

variable "container_min_replicas" {
  description = "Minimum number of container replicas (0 = scale to zero)"
  type        = number
  default     = 0
}

variable "container_max_replicas" {
  description = "Maximum number of container replicas"
  type        = number
  default     = 3
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "cosmos_db_config" {
  description = "Cosmos DB configuration"
  type = object({
    database_name = string
    containers = list(object({
      name                = string
      partition_key_paths = list(string)
      max_throughput      = optional(number, 1000) # Autoscale max RU/s
    }))
  })
}

variable "cosmos_db_free_tier" {
  description = "Enable Cosmos DB free tier (400 RU/s and 25 GB storage free)"
  type        = bool
  default     = true
}

variable "frontend_allowed_origins" {
  description = "List of allowed origins for CORS (frontend URLs)"
  type        = list(string)
  default     = []
}

variable "static_web_app_sku" {
  description = "SKU for Static Web App"
  type        = string
  default     = "Free"
}

variable "user_principal_id" {
  description = "Object ID of user to grant Cosmos DB access (for local development). If not provided, no user access is granted."
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (e.g., 'Production', 'Development')"
  type        = string
  default     = "Production"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
