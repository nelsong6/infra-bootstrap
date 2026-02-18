# ============================================================================
# Azure Login
# ============================================================================

Write-Host "[1/9] Azure Login..." -ForegroundColor Yellow
az login
az account set --subscription $script:SUBSCRIPTION_ID
Write-Host "[OK] Logged in to subscription: $script:SUBSCRIPTION_ID`n" -ForegroundColor Green

# Get tenant ID (needed for later)
$script:TENANT_ID = az account show --query tenantId -o tsv
