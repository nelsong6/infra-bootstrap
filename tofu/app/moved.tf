# ============================================================================
# State moves
# ============================================================================
#
# Historical (parent → web): resources that originally lived in the parent
# module and were extracted into the web sub-module. Kept as long as the
# `to` address is still a resource in `tofu/app/web/main.tf`.

moved {
  from = azurerm_role_assignment.appconfig_data_owner
  to   = module.web[0].azurerm_role_assignment.appconfig_data_owner
}

moved {
  from = azurerm_cosmosdb_sql_role_assignment.cosmos_data_reader
  to   = module.web[0].azurerm_cosmosdb_sql_role_assignment.cosmos_data_reader
}

moved {
  from = azuread_app_role_assignment.app_readwrite_owned
  to   = module.web[0].azuread_app_role_assignment.app_readwrite_owned
}

moved {
  from = azuread_application_federated_identity_credential.github_actions_prod
  to   = module.web[0].azuread_application_federated_identity_credential.github_actions_prod
}

moved {
  from = github_actions_variable.google_client_id
  to   = module.web[0].github_actions_variable.google_client_id
}

# ============================================================================
# Reverse (web → parent, gated): resources pulled back out of the web
# sub-module into the parent, now gated by an opt-in `count = var.<flag>`.
# Lets ci_only apps opt in to capabilities individually instead of needing
# the entire web bundle. Paired with the corresponding `var.<flag>` declared
# in `app/main.tf`.

moved {
  from = module.web[0].azurerm_role_assignment.storage_blob_contributor
  to   = azurerm_role_assignment.storage_blob_contributor[0]
}

moved {
  from = module.web[0].github_actions_variable.tfstate_storage_account
  to   = github_actions_variable.tfstate_storage_account[0]
}

moved {
  from = module.web[0].azurerm_role_assignment.contributor
  to   = azurerm_role_assignment.subscription_contributor[0]
}

moved {
  from = module.web[0].azurerm_role_assignment.rbac_admin
  to   = azurerm_role_assignment.rbac_admin[0]
}

moved {
  from = module.web[0].azurerm_role_assignment.keyvault_secrets_officer
  to   = azurerm_role_assignment.keyvault_secrets_officer[0]
}
