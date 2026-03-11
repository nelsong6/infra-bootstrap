# One-time import blocks to bring existing resources into the new Azure Storage state.
# Remove this file after the first successful tofu apply.

locals {
  _sub = "aee0cbd2-8074-4001-b610-0f8edb4eaa3c"
  _rg  = "infra"
  _dns = "romaine.life"
}

# ============================================================================
# Core Infrastructure (main.tf)
# ============================================================================

import {
  to = azurerm_container_app_environment.main
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.App/managedEnvironments/infra-aca"
}

import {
  to = azurerm_cosmosdb_account.main
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.DocumentDB/databaseAccounts/infra-cosmos"
}

import {
  to = azurerm_app_configuration.main
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.AppConfiguration/configurationStores/infra-appconfig"
}

import {
  to = azurerm_app_configuration_key.cosmos_db_endpoint
  id = "https://infra-appconfig.azconfig.io/kv/cosmos_db_endpoint?label=%00"
}

import {
  to = azurerm_app_configuration_key.auth0_domain
  id = "https://infra-appconfig.azconfig.io/kv/AUTH0_DOMAIN?label=%00"
}

import {
  to = azurerm_app_configuration_key.auth0_audience
  id = "https://infra-appconfig.azconfig.io/kv/AUTH0_AUDIENCE?label=%00"
}

# ============================================================================
# DNS (dns.tf)
# ============================================================================

import {
  to = azurerm_dns_zone.main
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}"
}

import {
  to = azurerm_dns_mx_record.email
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}/MX/@"
}

import {
  to = azurerm_dns_txt_record.apex
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}/TXT/@"
}

import {
  to = azurerm_dns_txt_record.dmarc
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}/TXT/_dmarc"
}

import {
  to = azurerm_dns_txt_record.dkim
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}/TXT/default._domainkey"
}

import {
  to = azurerm_dns_cname_record.autoconfig
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}/CNAME/autoconfig"
}

import {
  to = azurerm_dns_cname_record.auth0
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}/CNAME/auth"
}

import {
  to = azurerm_dns_cname_record.autodiscover
  id = "/subscriptions/${local._sub}/resourceGroups/${local._rg}/providers/Microsoft.Network/dnsZones/${local._dns}/CNAME/autodiscover"
}

# ============================================================================
# Auth0 (auth.tf)
# ============================================================================

import {
  to = auth0_tenant.main
  id = "dev-gtdi5x5p0nmticqd.us.auth0.com"
}

import {
  to = auth0_custom_domain.main
  id = "cd_UQTmrvIny5sKsN4e"
}

import {
  to = auth0_custom_domain_verification.main
  id = "cd_UQTmrvIny5sKsN4e"
}

import {
  to = auth0_connection.github
  id = "con_YGOtoiX1N3bLgWFk"
}

import {
  to = auth0_connection.google
  id = "con_kZUpzua9TliVC2QK"
}

import {
  to = auth0_connection.apple
  id = "con_DM1he2xMWnIQiVgg"
}

# ============================================================================
# OAuth / AzureAD (oauth.tf)
# ============================================================================

import {
  to = azuread_application.microsoft_login
  id = "/applications/59a001a7-6f87-4979-a850-efddb7c2459d"
}

import {
  to = azuread_application_password.microsoft_login
  id = "/applications/59a001a7-6f87-4979-a850-efddb7c2459d/passwords/55462e70-b513-4a89-aa3f-7d6fede0bf31"
}

import {
  to = azurerm_key_vault_secret.microsoft_oauth_client_id
  id = "https://romaine-kv.vault.azure.net/secrets/microsoft-oauth-client-id"
}

import {
  to = azurerm_key_vault_secret.microsoft_oauth_client_secret
  id = "https://romaine-kv.vault.azure.net/secrets/microsoft-oauth-client-secret"
}

import {
  to = azurerm_app_configuration_key.google_oauth_client_id
  id = "https://infra-appconfig.azconfig.io/kv/google_oauth_client_id?label=%00"
}

import {
  to = azurerm_app_configuration_key.google_oauth_client_secret
  id = "https://infra-appconfig.azconfig.io/kv/google_oauth_client_secret?label=%00"
}

import {
  to = azurerm_app_configuration_key.microsoft_oauth_client_id
  id = "https://infra-appconfig.azconfig.io/kv/microsoft_oauth_client_id?label=%00"
}

import {
  to = azurerm_app_configuration_key.microsoft_oauth_client_secret
  id = "https://infra-appconfig.azconfig.io/kv/microsoft_oauth_client_secret?label=%00"
}

# ============================================================================
# Landing Page (landing.tf) — additional imports beyond what's already there
# ============================================================================

import {
  to = azurerm_static_web_app_custom_domain.landing
  id = "/subscriptions/${local._sub}/resourceGroups/landing-page-rg/providers/Microsoft.Web/staticSites/landing-page-app/customDomains/romaine.life"
}

import {
  to = github_repository.landing_page
  id = "landing-page"
}

import {
  to = azuread_application_federated_identity_credential.landing_page_github_actions_main
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/66929b78-6058-4367-885e-d3ce95a1f69b"
}

import {
  to = azuread_application_federated_identity_credential.landing_page_github_actions_prod
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/233a4825-75ac-459b-b444-42489f38baeb"
}

import {
  to = github_actions_variable.landing_page_key_vault_name
  id = "landing-page:KEY_VAULT_NAME"
}

import {
  to = github_actions_variable.landing_page_arm_client_id
  id = "landing-page:ARM_CLIENT_ID"
}

import {
  to = github_actions_variable.landing_page_arm_tenant_id
  id = "landing-page:ARM_TENANT_ID"
}

import {
  to = github_actions_variable.landing_page_arm_subscription_id
  id = "landing-page:ARM_SUBSCRIPTION_ID"
}

# ============================================================================
# Module: app["bender-world"]
# ============================================================================

import {
  to = module.app["bender-world"].github_repository.repo
  id = "bender-world"
}

import {
  to = module.app["bender-world"].azuread_application_federated_identity_credential.github_actions_main
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/e153d5ad-62d9-4d06-a179-204ee3e2d10f"
}

import {
  to = module.app["bender-world"].azuread_application_federated_identity_credential.github_actions_prod
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/ae88a7fe-99ab-4845-b1ae-bbe06387c41f"
}

import {
  to = module.app["bender-world"].github_actions_variable.key_vault_name
  id = "bender-world:KEY_VAULT_NAME"
}

import {
  to = module.app["bender-world"].github_actions_variable.arm_client_id
  id = "bender-world:ARM_CLIENT_ID"
}

import {
  to = module.app["bender-world"].github_actions_variable.arm_tenant_id
  id = "bender-world:ARM_TENANT_ID"
}

import {
  to = module.app["bender-world"].github_actions_variable.arm_subscription_id
  id = "bender-world:ARM_SUBSCRIPTION_ID"
}

import {
  to = module.app["bender-world"].github_actions_variable.tfstate_storage_account
  id = "bender-world:TFSTATE_STORAGE_ACCOUNT"
}

# ============================================================================
# Module: app["eight-queens"]
# ============================================================================

import {
  to = module.app["eight-queens"].github_repository.repo
  id = "eight-queens"
}

import {
  to = module.app["eight-queens"].azuread_application_federated_identity_credential.github_actions_main
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/fb2561f7-d750-4687-b815-121c73e79045"
}

import {
  to = module.app["eight-queens"].azuread_application_federated_identity_credential.github_actions_prod
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/2745f2e9-e7c3-4790-9a94-918c46dc4de4"
}

import {
  to = module.app["eight-queens"].github_actions_variable.key_vault_name
  id = "eight-queens:KEY_VAULT_NAME"
}

import {
  to = module.app["eight-queens"].github_actions_variable.arm_client_id
  id = "eight-queens:ARM_CLIENT_ID"
}

import {
  to = module.app["eight-queens"].github_actions_variable.arm_tenant_id
  id = "eight-queens:ARM_TENANT_ID"
}

import {
  to = module.app["eight-queens"].github_actions_variable.arm_subscription_id
  id = "eight-queens:ARM_SUBSCRIPTION_ID"
}

# ============================================================================
# Module: app["kill-me"]
# ============================================================================

import {
  to = module.app["kill-me"].github_repository.repo
  id = "kill-me"
}

import {
  to = module.app["kill-me"].azuread_application_federated_identity_credential.github_actions_main
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/0ebdcb7c-b48a-470a-bf19-47df16957351"
}

import {
  to = module.app["kill-me"].azuread_application_federated_identity_credential.github_actions_prod
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/1e58155e-4b12-4469-b5ec-b7411871a737"
}

import {
  to = module.app["kill-me"].github_actions_variable.key_vault_name
  id = "kill-me:KEY_VAULT_NAME"
}

import {
  to = module.app["kill-me"].github_actions_variable.arm_client_id
  id = "kill-me:ARM_CLIENT_ID"
}

import {
  to = module.app["kill-me"].github_actions_variable.arm_tenant_id
  id = "kill-me:ARM_TENANT_ID"
}

import {
  to = module.app["kill-me"].github_actions_variable.arm_subscription_id
  id = "kill-me:ARM_SUBSCRIPTION_ID"
}

# ============================================================================
# Module: app["my-homepage"]
# ============================================================================

import {
  to = module.app["my-homepage"].github_repository.repo
  id = "my-homepage"
}

import {
  to = module.app["my-homepage"].azuread_application_federated_identity_credential.github_actions_main
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/30ee5c81-2df2-4b0d-87cf-ae5af2b9eeb8"
}

import {
  to = module.app["my-homepage"].azuread_application_federated_identity_credential.github_actions_prod
  id = "/applications/c343f4d9-5bdc-4938-bcd2-0f326c3ae478/federatedIdentityCredentials/4390a8fb-0177-403a-8ce1-fb5f9449525e"
}

import {
  to = module.app["my-homepage"].github_actions_variable.key_vault_name
  id = "my-homepage:KEY_VAULT_NAME"
}

import {
  to = module.app["my-homepage"].github_actions_variable.arm_client_id
  id = "my-homepage:ARM_CLIENT_ID"
}

import {
  to = module.app["my-homepage"].github_actions_variable.arm_tenant_id
  id = "my-homepage:ARM_TENANT_ID"
}

import {
  to = module.app["my-homepage"].github_actions_variable.arm_subscription_id
  id = "my-homepage:ARM_SUBSCRIPTION_ID"
}
