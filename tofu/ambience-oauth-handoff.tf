# One-time ownership handoff for the Ambience user-facing OAuth app.
#
# The app registration itself is managed by nelsong6/ambience/tofu. Bootstrap
# only grants the per-app CI principal enough ownership to manage the adopted
# registration with Application.ReadWrite.OwnedBy.

data "azuread_application" "ambience_oauth_handoff" {
  object_id = "0f8417f4-9ba1-4116-94bd-ae1a18b8f356"
}

resource "azuread_application_owner" "ambience_oauth_ci" {
  application_id  = data.azuread_application.ambience_oauth_handoff.id
  owner_object_id = module.app["ambience"].service_principal_object_id
}
