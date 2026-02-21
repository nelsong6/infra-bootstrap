# ============================================================================
# Azure Client Configuration
# ============================================================================
# Get the current Azure client configuration for use in outputs and
# role assignments. This provides information about the service principal
# or user running Terraform.

data "azurerm_client_config" "current" {}

