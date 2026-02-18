# ============================================================================
# Generate Backend Configuration
# ============================================================================

Write-Host "[9/9] Generating backend configuration..." -ForegroundColor Yellow

$backendContent = @"
terraform {
  backend "azurerm" {
    resource_group_name  = "$script:TFSTATE_RG_NAME"
    storage_account_name = "$script:STORAGE_NAME"
    container_name       = "$script:CONTAINER_NAME"
    key                  = "terraform.tfstate"
    use_oidc             = true
  }
}
"@

# Ensure directory exists
if (-not (Test-Path "tofu")) {
    New-Item -ItemType Directory -Force -Path "tofu" | Out-Null
}

# Write the file
$backendContent | Out-File -FilePath $script:TARGET_FILE -Encoding utf8
Write-Host "[OK] Backend configuration saved to: $script:TARGET_FILE`n" -ForegroundColor Green
