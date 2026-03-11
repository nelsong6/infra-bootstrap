# ============================================================================
# Azure Client Configuration
# ============================================================================
# Get the current Azure client configuration for use in outputs and
# role assignments. This provides information about the service principal
# or user running Terraform.

data "azurerm_client_config" "current" {}

# ============================================================================
# Auth0 Custom Domain
# ============================================================================
# Creates the custom domain in Auth0 and verifies it once the DNS CNAME record
# is in place. Auth0 returns the CNAME target via the verification block, which
# dns.tf references so the value never needs to be hardcoded.

resource "auth0_tenant" "main" {
  friendly_name = azurerm_dns_zone.main.name
}

resource "auth0_custom_domain" "main" {
  domain = "auth.${azurerm_dns_zone.main.name}"
  type   = "auth0_managed_certs"
}

resource "auth0_custom_domain_verification" "main" {
  custom_domain_id = auth0_custom_domain.main.id

  timeouts {
    create = "15m"
  }

  depends_on = [azurerm_dns_cname_record.auth0]
}

# ============================================================================
# Auth0 Social Connections (Tenant-Level)
# ============================================================================
# These identity providers are shared across all applications. Each app links
# to the connections it needs via auth0_connection_clients in its own stack.
# NOTE: These use Auth0 "Developer Keys" for testing. For production, add
# real OAuth credentials in an options {} block on each connection.

resource "auth0_connection" "github" {
  name     = "github"
  strategy = "github"
}

resource "auth0_connection" "google" {
  name     = "google-oauth2"
  strategy = "google-oauth2"
}

resource "auth0_connection" "apple" {
  name     = "apple"
  strategy = "apple"
}


