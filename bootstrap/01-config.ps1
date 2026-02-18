# ============================================================================
# Configuration
# ============================================================================

# Repository and Azure configuration
$script:REPO = "nelsong6/kill-me"
$script:SUBSCRIPTION_ID = "aee0cbd2-8074-4001-b610-0f8edb4eaa3c"
$script:APP_NAME = "GitHub-Actions-Terraform-Bootstrap"

# Storage configuration
$script:TFSTATE_RG_NAME = "infra"
$script:STORAGE_NAME = "tfstate" + (Get-Random -Minimum 1000 -Maximum 9999)
$script:CONTAINER_NAME = "tfstate"

# Output configuration file location
$script:TARGET_FILE = "tofu/backend.tf"

Write-Host "Configuration loaded" -ForegroundColor Gray
