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

resource "auth0_custom_domain" "main" {
  domain = "auth.romaine.life"
  type   = "auth0_managed_certs"
}

resource "auth0_custom_domain_verification" "main" {
  custom_domain_id = auth0_custom_domain.main.id

  timeouts {
    create = "15m"
  }

  depends_on = [azurerm_dns_cname_record.auth0]
}
