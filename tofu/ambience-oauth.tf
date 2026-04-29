# ============================================================================
# Ambience user-auth Entra app
# ============================================================================
# Distinct from module.app["ambience"]'s OIDC-only app (used by GitHub
# Actions). This one is the front door for ambience users logging in.
# Sign-in audience is single-tenant (AzureADMyOrg) because Entra only
# permits wildcard redirect URIs on web-platform apps with single- or
# multi-tenant audience — personal MSA accounts disallow wildcards.
#
# Wildcard URI lets per-issue and per-PR ephemeral environments at
# *.ambience.dev.romaine.life complete the OAuth round-trip without
# re-registering each ephemeral hostname.

resource "azuread_application" "ambience_oauth" {
  display_name     = "ambience-oauth"
  sign_in_audience = "AzureADMyOrg"

  owners = [data.azurerm_client_config.current.object_id]

  api {
    requested_access_token_version = 2
  }

  web {
    redirect_uris = [
      "https://ambience.romaine.life/auth/callback",
      "https://ambience.dev.romaine.life/auth/callback",
      "https://*.ambience.dev.romaine.life/auth/callback",
    ]

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "ambience_oauth" {
  client_id = azuread_application.ambience_oauth.client_id
}

resource "azurerm_key_vault_secret" "ambience_oauth_client_id" {
  name         = "ambience-oauth-client-id"
  value        = azuread_application.ambience_oauth.client_id
  key_vault_id = data.azurerm_key_vault.main.id
}
