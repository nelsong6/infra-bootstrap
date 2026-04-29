# ============================================================================
# Agent-run screenshot storage
# ============================================================================
# Public-blob storage for screenshots emitted by agentic-CI flows. The PR
# body uses raw blob URLs as image markdown so reviewers see screenshots
# inline. Per-app containers keep the namespace clean and let us delete
# all of an app's screenshots without touching others.
#
# Why not commit screenshots to the agent's branch:
#   - bloats git history (PNGs are binary)
#   - bloats PR diff (reviewer sees code + binary blobs)
#   - requires force-push --amend on the agent's existing commit
#
# Why not GHA artifacts only:
#   - workflow-run-scoped URLs require login + zip download
#   - no inline image rendering in PR body
#
# Mirrors the spirelens screenshot-storage pattern but lives in
# infra-bootstrap rather than per-app tofu — at this scale, a single
# shared account with per-app containers is simpler than every app
# growing its own state-backed tofu module.
# ============================================================================

resource "azurerm_storage_account" "agent_screenshots" {
  name                     = "infraagentscreens"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Required for `container_access_type = "blob"` below to take effect.
  allow_nested_items_to_be_public = true

  blob_properties {
    # Agent-run screenshots are evidence for in-flight PRs; they age out
    # of usefulness fast. 90 days bounds storage growth without truncating
    # PRs that take a while to merge.
    delete_retention_policy {
      days = 90
    }
  }
}

# Per-app container. New apps register by adding a container + role
# assignment for their CI SP here.
resource "azurerm_storage_container" "agent_screenshots_ambience" {
  name                  = "ambience"
  storage_account_id    = azurerm_storage_account.agent_screenshots.id
  container_access_type = "blob"
}

# ambience's CI SP (created by module.app["ambience"]) gets write access to
# its own container. Look up by display name rather than threading a
# module output — keeps the agent-screenshots concern self-contained.
data "azuread_service_principal" "ambience_ci" {
  display_name = "ambience"
}

resource "azurerm_role_assignment" "ambience_screenshots_uploader" {
  scope                = azurerm_storage_container.agent_screenshots_ambience.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azuread_service_principal.ambience_ci.object_id
}

# Push the storage details to the ambience repo as Actions variables so
# the agent-run workflow can consume them without round-tripping through
# tofu output. State is still authoritative; this is just convenience
# wiring (matches the existing app-config / KV-vault pattern).
resource "github_actions_variable" "ambience_screenshot_storage_account" {
  repository    = "ambience"
  variable_name = "AGENT_SCREENSHOT_STORAGE_ACCOUNT"
  value         = azurerm_storage_account.agent_screenshots.name
}

resource "github_actions_variable" "ambience_screenshot_container" {
  repository    = "ambience"
  variable_name = "AGENT_SCREENSHOT_CONTAINER"
  value         = azurerm_storage_container.agent_screenshots_ambience.name
}

resource "github_actions_variable" "ambience_screenshot_container_url" {
  repository    = "ambience"
  variable_name = "AGENT_SCREENSHOT_CONTAINER_URL"
  value         = "https://${azurerm_storage_account.agent_screenshots.name}.blob.core.windows.net/${azurerm_storage_container.agent_screenshots_ambience.name}"
}
