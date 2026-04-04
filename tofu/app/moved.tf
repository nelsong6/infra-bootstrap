# ============================================================================
# State moves — resources extracted from this module into the web sub-module.
# These tell OpenTofu where existing state objects now live.
# ============================================================================

moved {
  from = azurerm_role_assignment.contributor
  to   = module.web[0].azurerm_role_assignment.contributor
}

moved {
  from = azurerm_role_assignment.rbac_admin
  to   = module.web[0].azurerm_role_assignment.rbac_admin
}

moved {
  from = azurerm_role_assignment.keyvault_secrets_officer
  to   = module.web[0].azurerm_role_assignment.keyvault_secrets_officer
}

moved {
  from = azurerm_role_assignment.appconfig_data_owner
  to   = module.web[0].azurerm_role_assignment.appconfig_data_owner
}

moved {
  from = azurerm_role_assignment.storage_blob_reader
  to   = module.web[0].azurerm_role_assignment.storage_blob_reader
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
  from = github_actions_variable.tfstate_storage_account
  to   = module.web[0].github_actions_variable.tfstate_storage_account
}

moved {
  from = github_actions_variable.google_client_id
  to   = module.web[0].github_actions_variable.google_client_id
}
