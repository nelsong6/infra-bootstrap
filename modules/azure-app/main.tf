# ============================================================================
# Azure App Module - Main Resources
# ============================================================================

# Local variables
locals {
  github_parts     = split("/", var.github_repo)
  github_owner     = local.github_parts[0]
  github_repo_name = local.github_parts[1]

  # Construct full domain names
  frontend_domain = "${var.custom_domain_subdomain}.${var.dns_zone_name}"
  backend_domain  = "api.${var.custom_domain_subdomain}.${var.dns_zone_name}"

  # Default tags merged with custom tags
  default_tags = {
    Environment = var.environment
    Project     = var.app_name
    ManagedBy   = "Terraform"
  }
  tags = merge(local.default_tags, var.tags)
}

# Random suffix for globally unique names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Get DNS zone data
data "azurerm_dns_zone" "main" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
}

# ============================================================================
# Azure Static Web App (Frontend)
# ============================================================================

resource "azurerm_static_web_app" "frontend" {
  name                = "${var.app_name}-app-${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_tier            = var.static_web_app_sku
  sku_size            = var.static_web_app_sku

  tags = local.tags
}

# Grant Website Contributor role for GitHub Actions deployment
resource "azurerm_role_assignment" "github_actions_static_web_app" {
  scope                = azurerm_static_web_app.frontend.id
  role_definition_name = "Website Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ============================================================================
# Azure Cosmos DB
# ============================================================================

resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.app_name}-cosmos-${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  free_tier_enabled          = var.cosmos_db_free_tier
  automatic_failover_enabled = false

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = local.tags
}

# Cosmos DB Database
resource "azurerm_cosmosdb_sql_database" "main" {
  name                = var.cosmos_db_config.database_name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
}

# Cosmos DB Containers
resource "azurerm_cosmosdb_sql_container" "containers" {
  for_each = { for idx, container in var.cosmos_db_config.containers : container.name => container }

  name                = each.value.name
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_paths = each.value.partition_key_paths

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }
  }
}

# Grant user Cosmos DB Data Contributor role (for local development)
resource "azurerm_cosmosdb_sql_role_assignment" "user_data_contributor" {
  count = var.user_principal_id != null ? 1 : 0

  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  role_definition_id  = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.user_principal_id
  scope               = azurerm_cosmosdb_account.main.id
}

# ============================================================================
# Azure Container Apps (Backend API)
# ============================================================================

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                = "${var.app_name}-env-${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.tags
}

# Container App
resource "azurerm_container_app" "api" {
  name                         = "${var.app_name}-api"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "${var.app_name}-api"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "COSMOS_DB_ENDPOINT"
        value = azurerm_cosmosdb_account.main.endpoint
      }

      env {
        name  = "COSMOS_DB_DATABASE_NAME"
        value = azurerm_cosmosdb_sql_database.main.name
      }

      env {
        name  = "COSMOS_DB_CONTAINER_NAME"
        value = var.cosmos_db_config.containers[0].name
      }

      env {
        name  = "PORT"
        value = tostring(var.container_port)
      }

      env {
        name  = "FRONTEND_URL"
        value = "https://${local.frontend_domain}"
      }
    }

    min_replicas = var.container_min_replicas
    max_replicas = var.container_max_replicas
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }

    # CORS configuration
    cors {
      allowed_origins = concat(
        [
          "https://${local.frontend_domain}",
          "https://${azurerm_static_web_app.frontend.default_host_name}",
        ],
        var.frontend_allowed_origins
      )

      allowed_methods           = ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"]
      allowed_headers           = ["*"]
      exposed_headers           = ["*"]
      max_age_in_seconds        = 3600
      allow_credentials_enabled = true
    }
  }

  tags = local.tags
}

# Grant Container App managed identity access to Cosmos DB
resource "azurerm_cosmosdb_sql_role_assignment" "container_app_cosmos" {
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  role_definition_id  = "${azurerm_cosmosdb_account.main.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = azurerm_container_app.api.identity[0].principal_id
  scope               = azurerm_cosmosdb_account.main.id
}

# ============================================================================
# DNS Configuration
# ============================================================================

# Frontend CNAME record
resource "azurerm_dns_cname_record" "frontend" {
  name                = var.custom_domain_subdomain
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = azurerm_static_web_app.frontend.default_host_name

  tags = local.tags
}

# Backend CNAME record
resource "azurerm_dns_cname_record" "backend" {
  name                = "api.${var.custom_domain_subdomain}"
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  record              = azurerm_container_app.api.ingress[0].fqdn

  tags = local.tags
}

# TXT record for Container App domain verification
resource "azurerm_dns_txt_record" "backend_verification" {
  name                = "asuid.api.${var.custom_domain_subdomain}"
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 3600

  record {
    value = azurerm_container_app.api.custom_domain_verification_id
  }

  tags = local.tags
}

# DNS propagation delay
resource "time_sleep" "wait_for_dns" {
  depends_on = [
    azurerm_dns_cname_record.frontend,
    azurerm_dns_cname_record.backend,
    azurerm_dns_txt_record.backend_verification
  ]

  create_duration = "90s"
}

# ============================================================================
# Custom Domain Bindings
# ============================================================================

# Custom domain for Static Web App
resource "azurerm_static_web_app_custom_domain" "frontend" {
  static_web_app_id = azurerm_static_web_app.frontend.id
  domain_name       = local.frontend_domain
  validation_type   = "cname-delegation"

  depends_on = [
    azurerm_dns_cname_record.frontend,
    time_sleep.wait_for_dns
  ]
}

# Custom domain for Container App
resource "azurerm_container_app_custom_domain" "backend" {
  name                                     = local.backend_domain
  container_app_id                         = azurerm_container_app.api.id
  container_app_environment_certificate_id = null
  certificate_binding_type                 = "SniEnabled"

  depends_on = [
    azurerm_dns_cname_record.backend,
    azurerm_dns_txt_record.backend_verification,
    time_sleep.wait_for_dns
  ]
}

# ============================================================================
# GitHub Integration (Secrets and Variables)
# ============================================================================

# Configure GitHub secrets
resource "github_actions_secret" "cosmos_db_endpoint" {
  repository      = local.github_repo_name
  secret_name     = "COSMOS_DB_ENDPOINT"
  plaintext_value = azurerm_cosmosdb_account.main.endpoint
}

# Configure GitHub variables
resource "github_actions_variable" "cosmos_db_database_name" {
  repository    = local.github_repo_name
  variable_name = "COSMOS_DB_DATABASE_NAME"
  value         = azurerm_cosmosdb_sql_database.main.name
}

resource "github_actions_variable" "cosmos_db_container_name" {
  repository    = local.github_repo_name
  variable_name = "COSMOS_DB_CONTAINER_NAME"
  value         = var.cosmos_db_config.containers[0].name
}

resource "github_actions_variable" "static_web_app_name" {
  repository    = local.github_repo_name
  variable_name = "STATIC_WEB_APP_NAME"
  value         = azurerm_static_web_app.frontend.name
}

resource "github_actions_variable" "resource_group_name" {
  repository    = local.github_repo_name
  variable_name = "RESOURCE_GROUP_NAME"
  value         = var.resource_group_name
}
