output "managed_identity_client_id" {
  value       = azurerm_user_assigned_identity.mcp.client_id
  description = "Client ID of the MCP server's managed identity. Set as the azure.workload.identity/client-id annotation on the K8s ServiceAccount."
}

output "managed_identity_principal_id" {
  value       = azurerm_user_assigned_identity.mcp.principal_id
  description = "Principal ID of the MCP server's managed identity."
}

output "resource_application_id" {
  value       = azuread_application.resource.client_id
  description = "Entra application (client) ID of the MCP server's resource app. Tokens presented by clients have this as aud."
}

output "resource_application_object_id" {
  value       = azuread_application.resource.object_id
  description = "Entra application object ID of the resource app (used for granting admin consent etc.)."
}

output "invoke_scope_value" {
  value       = "Mcp.Tools.ReadWrite"
  description = "OAuth2 scope value the client must request. Present in tokens as scp."
}

output "identifier_uri" {
  value       = "api://${azuread_application.resource.client_id}"
  description = "Token audience value clients pass when requesting tokens. Equal to identifier_uris[0]."
}
