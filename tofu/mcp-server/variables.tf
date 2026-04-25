variable "name" {
  description = "Short name of the MCP server (e.g. 'azure'). Used for resource naming and the subdomain mcp-<name>.<dns_zone>."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster — used for federating the pod service account to this server's Entra app."
  type        = string
}

variable "aks_namespace" {
  description = "K8s namespace the MCP server runs in. Conventionally mcp-<name>."
  type        = string
}

variable "aks_service_account_name" {
  description = "K8s ServiceAccount the MCP pod uses. Conventionally mcp-<name>."
  type        = string
}

variable "claude_client_application_id" {
  description = "Entra application (object) ID of the shared Claude MCP client. Pre-authorized for this server's scope so users don't get a consent prompt when adding the integration."
  type        = string
}

variable "claude_client_client_id" {
  description = "Entra application client ID of the shared Claude MCP client. Used as knownClientApplication so the server's scope shows up in Claude's consent."
  type        = string
}

variable "additional_pre_authorized_client_ids" {
  description = "Extra OAuth client app IDs that can obtain tokens for this MCP server's scope without an explicit consent prompt — e.g. Microsoft Azure CLI for personal-MCP scenarios where the operator wants `az account get-access-token` to Just Work."
  type        = set(string)
  default     = []
}

variable "role_assignments" {
  description = "Azure RBAC roles granted to the signed-in user pool via the MCP server's token exchange — applied to this map's scopes. Use an Entra group (via Azure AD RBAC on the group as principal) to restrict who can use the server."
  type = map(object({
    scope                = string
    role_definition_name = string
    principal_id         = string
  }))
  default = {}
}
