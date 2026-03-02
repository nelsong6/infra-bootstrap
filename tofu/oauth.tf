# ============================================================================
# Shared OAuth App Registrations
# ============================================================================
# OAuth credentials shared across all projects (my-homepage, kill-me, etc.).
# Microsoft: Azure AD App Registration managed here.
# Google:    Created via bootstrap/setup-google-oauth.ps1, secrets in Key Vault.
# GitHub:    GitHub App created via bootstrap/setup-github-app.ps1.

# ============================================================================
# Microsoft "Sign in with Microsoft" (shared across all projects)
# ============================================================================

resource "azuread_application" "microsoft_login" {
  display_name     = "romaine.life - Social Login"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  api {
    requested_access_token_version = 2
  }

  web {
    redirect_uris = [
      # my-homepage (direct passport-microsoft)
      "https://homepage.api.romaine.life/auth/microsoft/callback",
      "https://homepage-api.${azurerm_container_app_environment.main.default_domain}/auth/microsoft/callback",
      "http://localhost:3000/auth/microsoft/callback",
      # kill-me — add redirect URIs here when ready
    ]
  }
}

resource "azuread_application_password" "microsoft_login" {
  application_id = azuread_application.microsoft_login.id
  display_name   = "passport-microsoft"
}

# Store Microsoft OAuth credentials in shared Key Vault so backends can
# read them at runtime via managed identity.

resource "azurerm_key_vault_secret" "microsoft_oauth_client_id" {
  name         = "microsoft-oauth-client-id"
  value        = azuread_application.microsoft_login.client_id
  key_vault_id = data.azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "microsoft_oauth_client_secret" {
  name         = "microsoft-oauth-client-secret"
  value        = azuread_application_password.microsoft_login.value
  key_vault_id = data.azurerm_key_vault.main.id
}

# ============================================================================
# Google "Sign in with Google" (shared across all projects)
# ============================================================================
# Google OAuth credentials are created manually via the GCP Console and stored
# in Key Vault by bootstrap/setup-google-oauth.ps1. We read them as data
# sources so Terraform can reference them in App Configuration.

data "azurerm_key_vault_secret" "google_oauth_client_id" {
  name         = "google-oauth-client-id"
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault_secret" "google_oauth_client_secret" {
  name         = "google-oauth-client-secret"
  key_vault_id = data.azurerm_key_vault.main.id
}

# ============================================================================
# App Configuration Key Vault References (shared across all projects)
# ============================================================================
# These let apps read OAuth credentials from App Configuration, which resolves
# the actual values from Key Vault transparently.

resource "azurerm_app_configuration_key" "google_oauth_client_id" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "google_oauth_client_id"
  type                   = "vault"
  vault_key_reference    = data.azurerm_key_vault_secret.google_oauth_client_id.versionless_id
}

resource "azurerm_app_configuration_key" "google_oauth_client_secret" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "google_oauth_client_secret"
  type                   = "vault"
  vault_key_reference    = data.azurerm_key_vault_secret.google_oauth_client_secret.versionless_id
}

resource "azurerm_app_configuration_key" "microsoft_oauth_client_id" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "microsoft_oauth_client_id"
  type                   = "vault"
  vault_key_reference    = azurerm_key_vault_secret.microsoft_oauth_client_id.versionless_id
}

resource "azurerm_app_configuration_key" "microsoft_oauth_client_secret" {
  configuration_store_id = azurerm_app_configuration.main.id
  key                    = "microsoft_oauth_client_secret"
  type                   = "vault"
  vault_key_reference    = azurerm_key_vault_secret.microsoft_oauth_client_secret.versionless_id
}
