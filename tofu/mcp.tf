
# ============================================================================
# MCP (Model Context Protocol) Servers
# ============================================================================
# Each MCP server exposes a set of tools to LLM clients (Claude web, Claude
# Desktop, etc.) over HTTPS. Auth is OAuth 2.1 with PKCE against Entra ID:
# Claude is pre-registered as a public client, each server is its own
# resource/audience exposing a single invoke scope. Server pods validate
# tokens themselves (built into azure-mcp's HTTP transport) and perform the
# OBO flow to call Azure as the signed-in user — no client secrets anywhere.
#
# Per-server Azure resources (managed identity, federated credentials,
# resource Entra app, scope grants, role assignments, KV secrets) live in
# the ./mcp-server module. Everything shared (Claude client app, DNS
# records) lives here.
# ============================================================================

# ----------------------------------------------------------------------------
# Shared: Claude as the OAuth client
# ----------------------------------------------------------------------------
# One Entra app registration represents Claude (web + desktop + Code) as the
# *client* of any MCP server we host. Public client with PKCE — no secret
# leaves Entra. Redirect URIs cover the documented callbacks for each
# surface; add more as Anthropic publishes them.

resource "azuread_application" "mcp_client" {
  display_name     = "Claude MCP Client"
  sign_in_audience = "AzureADMyOrg"

  api {
    requested_access_token_version = 2
  }

  public_client {
    redirect_uris = [
      # claude.ai remote-MCP callback. Verify against Anthropic's current
      # docs before initial bring-up — they've rev'd this path before.
      "https://claude.ai/api/mcp/auth_callback",
      # Claude Desktop and Claude Code use a local loopback; Entra accepts
      # http://localhost with any port for public clients.
      "http://localhost",
    ]
  }

  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "mcp_client" {
  client_id = azuread_application.mcp_client.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# Published for consumption by k8s manifests (ConfigMap for the .well-known
# OAuth resource document, etc.).
resource "azurerm_key_vault_secret" "mcp_client_id" {
  name         = "mcp-client-id"
  value        = azuread_application.mcp_client.client_id
  key_vault_id = data.azurerm_key_vault.main.id
}

# ----------------------------------------------------------------------------
# Per-server: azure
# ----------------------------------------------------------------------------
# Hosts Microsoft's azure-mcp (Azure SDK tooling surface) at
# azure.mcp.romaine.life. Role assignments are empty here — grants happen
# against signed-in users (via OBO), so add users or an Entra group to the
# map once the server is up and tested.

module "mcp_azure" {
  source = "./mcp-server"

  name                       = "azure"
  resource_group_name        = data.azurerm_resource_group.main.name
  resource_group_location    = data.azurerm_resource_group.main.location
  key_vault_id               = data.azurerm_key_vault.main.id
  aks_oidc_issuer_url        = azurerm_kubernetes_cluster.main.oidc_issuer_url
  aks_namespace              = "mcp-azure"
  aks_service_account_name   = "mcp-azure"
  claude_client_application_id = azuread_application.mcp_client.object_id
  claude_client_client_id      = azuread_application.mcp_client.client_id

  # Populate with user/group object IDs and the desired scope once ready:
  #   role_assignments = {
  #     "nelson-reader" = {
  #       scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  #       role_definition_name = "Reader"
  #       principal_id         = "<nelson's object id or a group's object id>"
  #     }
  #   }
  role_assignments = {}
}

# ----------------------------------------------------------------------------
# DNS — per-host A records point at the Envoy Gateway's public IP.
# ----------------------------------------------------------------------------
# ExternalDNS manages records driven by HTTPRoute resources, so we don't
# write them here — kept as a note so future MCP servers follow the same
# pattern (HTTPRoute → ExternalDNS → A record).
