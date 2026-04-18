# ============================================================================
# Landing Page - Azure Static Web App (romaine.life)
# ============================================================================
# The landing page is a simple static site hosted on the apex domain.
# Its infrastructure lives here because the apex DNS records are a shared
# concern (they share the @ TXT record set with SPF/DKIM/Google verification).
# The app code lives separately in the landing-page repository.
# ============================================================================

resource "azurerm_resource_group" "landing" {
  name     = "landing-page-rg"
  location = data.azurerm_resource_group.main.location
}

resource "azurerm_static_web_app" "landing" {
  name                = "landing-page-app"
  resource_group_name = azurerm_resource_group.landing.name
  location            = azurerm_resource_group.landing.location
  sku_tier            = "Free"
  sku_size            = "Free"

  lifecycle {
    ignore_changes = [
      repository_url,
      repository_branch
    ]
  }
}

# ============================================================================
# DNS — Apex domain
# ============================================================================
# The A record points the apex domain to the Static Web App.
# The TXT validation record is merged into the shared @ TXT record in dns.tf.

resource "azurerm_dns_a_record" "landing_apex" {
  name                = "@"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  target_resource_id  = azurerm_static_web_app.landing.id
}

resource "azurerm_static_web_app_custom_domain" "landing" {
  static_web_app_id = azurerm_static_web_app.landing.id
  domain_name       = azurerm_dns_zone.main.name
  validation_type   = "dns-txt-token"
}

# ============================================================================
# GitHub Repository & CI/CD Configuration
# ============================================================================
# CI/CD runs via GitHub Actions (reusable workflows from pipeline-templates).

resource "github_repository" "landing_page" {
  name       = "landing-page"
  visibility = "public"
  auto_init  = true

  has_issues = true

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  delete_branch_on_merge = true
}

data "azuread_application" "main" {
  client_id = data.azurerm_client_config.current.client_id
}

resource "azuread_application_federated_identity_credential" "landing_page_github_actions_main" {
  application_id = data.azuread_application.main.id
  display_name   = "landing-page-github-actions-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${github_repository.landing_page.full_name}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "landing_page_github_actions_prod" {
  application_id = data.azuread_application.main.id
  display_name   = "landing-page-github-actions-prod"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${github_repository.landing_page.full_name}:environment:prod"
}

resource "github_actions_variable" "landing_page_key_vault_name" {
  repository    = github_repository.landing_page.name
  variable_name = "KEY_VAULT_NAME"
  value         = data.azurerm_key_vault.main.name
}

resource "github_actions_variable" "landing_page_arm_client_id" {
  repository    = github_repository.landing_page.name
  variable_name = "ARM_CLIENT_ID"
  value         = data.azurerm_client_config.current.client_id
}

resource "github_actions_variable" "landing_page_arm_tenant_id" {
  repository    = github_repository.landing_page.name
  variable_name = "ARM_TENANT_ID"
  value         = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_variable" "landing_page_arm_subscription_id" {
  repository    = github_repository.landing_page.name
  variable_name = "ARM_SUBSCRIPTION_ID"
  value         = data.azurerm_client_config.current.subscription_id
}

