terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# ============================================================================
# Managed Identity
# ============================================================================
# Dedicated identity for this MCP server's pod. Separate from the shared
# infra-shared-identity so role assignments stay scoped to just this server.
# The pod authenticates via workload identity (federated credential below);
# the identity itself is used for any direct Azure calls the server makes
# outside of the OBO path (e.g. diagnostics, health checks).

resource "azurerm_user_assigned_identity" "mcp" {
  name                = "mcp-${var.name}-identity"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
}

resource "azurerm_federated_identity_credential" "pod" {
  name                = "aks-mcp-${var.name}"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.mcp.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:${var.aks_namespace}:${var.aks_service_account_name}"
}

# ============================================================================
# Entra App Registration — MCP Server as OAuth Resource
# ============================================================================
# This app registration represents the MCP server as an OAuth *resource* (the
# audience of tokens Claude presents). It exposes a delegated scope that the
# Claude client is pre-authorized for, and requests delegated access to Azure
# Resource Manager so the OBO token exchange can swap the user's token for an
# ARM token. The app's own credential (for OBO) is provided by a federated
# identity credential tied to the pod's workload identity — no client secret.

resource "random_uuid" "invoke_scope" {}

resource "azuread_application" "resource" {
  display_name     = "MCP - ${var.name}"
  sign_in_audience = "AzureADMyOrg"

  # Required so the Claude client can surface this scope to the user during
  # consent and so tokens include it in the scp claim (v2 format).
  api {
    requested_access_token_version = 2

    known_client_applications = [var.claude_client_client_id]

    oauth2_permission_scope {
      id                         = random_uuid.invoke_scope.result
      value                      = "Mcp.Tools.ReadWrite"
      type                       = "User"
      admin_consent_display_name = "Invoke MCP tools"
      admin_consent_description  = "Allows the client to invoke tools on the ${var.name} MCP server on behalf of the signed-in user."
      user_consent_display_name  = "Invoke MCP tools"
      user_consent_description   = "Allow the MCP client to invoke tools on the ${var.name} MCP server as you."
      enabled                    = true
    }
  }

  # The MCP server does the OBO exchange to call ARM as the signed-in user.
  # Delegated "user_impersonation" on ARM is what lets that exchange succeed.
  # ARM's app ID (797f4846-ba00-4fd7-ba43-dae4c72140fc) is a well-known
  # Microsoft-owned constant.
  required_resource_access {
    resource_app_id = "797f4846-ba00-4fd7-ba43-dae4c72140fc"
    resource_access {
      # user_impersonation delegated permission on ARM
      id   = "41094075-9dad-400e-a0bd-54e686782033"
      type = "Scope"
    }
  }

  owners = [data.azuread_client_config.current.object_id]

  lifecycle {
    # identifier_uris depends on the app's object ID, which isn't known until
    # after creation. Managed via azuread_application_identifier_uri below.
    ignore_changes = [identifier_uris]
  }
}

data "azuread_client_config" "current" {}

# The identifier URI is what goes in the `aud` claim of tokens. Standard
# pattern is api://<client-id>.
resource "azuread_application_identifier_uri" "resource" {
  application_id = azuread_application.resource.id
  identifier_uri = "api://${azuread_application.resource.client_id}"
}

# Pre-authorize the Claude client for the invoke scope.
resource "azuread_application_pre_authorized" "claude" {
  application_id       = azuread_application.resource.id
  authorized_client_id = var.claude_client_client_id
  permission_ids       = [random_uuid.invoke_scope.result]
}

resource "azuread_service_principal" "resource" {
  client_id = azuread_application.resource.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

# ============================================================================
# OBO Federated Credential — MCP Server Entra App ← Pod Workload Identity
# ============================================================================
# During the OBO flow the MCP server calls Entra's /oauth2/v2.0/token endpoint
# as itself (the resource app). Rather than giving the app a client_secret,
# we federate: the pod presents its AKS-issued service-account JWT as the
# client_assertion, and Entra trusts it because of this credential.

resource "azuread_application_federated_identity_credential" "obo_pod" {
  application_id = azuread_application.resource.id
  display_name   = "aks-mcp-${var.name}-obo"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = var.aks_oidc_issuer_url
  subject        = "system:serviceaccount:${var.aks_namespace}:${var.aks_service_account_name}"
}

# ============================================================================
# Role Assignments
# ============================================================================
# OBO means Azure calls happen as the signed-in user, so role grants go on
# the user (or a group containing them), not on the MCP server's identity.
# Callers pass in whatever group/user principal ID they want to grant.

resource "azurerm_role_assignment" "granted" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# ============================================================================
# Key Vault outputs — published so k8s ExternalSecret can pull them
# ============================================================================
# The MCP server pod needs: tenant ID, the resource app's client ID (for the
# JWT audience check), and the managed identity's client ID (for workload
# identity annotations on the service account). Storing them in KV keeps
# values rotatable without re-deploying manifests.

resource "azurerm_key_vault_secret" "resource_client_id" {
  name         = "mcp-${var.name}-resource-client-id"
  value        = azuread_application.resource.client_id
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "managed_identity_client_id" {
  name         = "mcp-${var.name}-mi-client-id"
  value        = azurerm_user_assigned_identity.mcp.client_id
  key_vault_id = var.key_vault_id
}
