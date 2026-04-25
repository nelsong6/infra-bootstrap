# ============================================================================
# claude-container CI — image build from infra-bootstrap
# ============================================================================
# The Dockerfile lives in this repo under claude-container/. Same arrangement
# as mcp-github-ci.tf: dedicated SP for the build workflow, AcrPush on the
# shared registry, federated only for main.

resource "azuread_application" "claude_container_ci" {
  display_name = "claude-container-ci"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "claude_container_ci" {
  client_id = azuread_application.claude_container_ci.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_federated_identity_credential" "claude_container_ci_main" {
  application_id = azuread_application.claude_container_ci.id
  display_name   = "infra-bootstrap-claude-container-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:nelsong6/infra-bootstrap:ref:refs/heads/main"
}

resource "azurerm_role_assignment" "claude_container_ci_acr_push" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.claude_container_ci.object_id
}

resource "github_actions_variable" "claude_container_ci_client_id" {
  repository    = "infra-bootstrap"
  variable_name = "CLAUDE_CONTAINER_CI_CLIENT_ID"
  value         = azuread_application.claude_container_ci.client_id
}
