# ============================================================================
# Azure Login
# ============================================================================

Write-Host "[1/9] Azure Login..." -ForegroundColor Yellow

$PreviousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$_currentSub = az account show --query id -o tsv 2>$null
$_loginExitCode = $LASTEXITCODE
$ErrorActionPreference = $PreviousErrorActionPreference

if ($_loginExitCode -eq 0 -and $_currentSub -eq $script:SUBSCRIPTION_ID) {
    Write-Host "  Already logged in to correct subscription, skipping login" -ForegroundColor Gray
} elseif ($_loginExitCode -eq 0) {
    Write-Host "  Switching to subscription: $script:SUBSCRIPTION_ID..." -ForegroundColor Gray
    az account set --subscription $script:SUBSCRIPTION_ID --output none
} else {
    Write-Host "  Authenticating..." -ForegroundColor Gray
    az login --output none
    az account set --subscription $script:SUBSCRIPTION_ID --output none
}

# Get tenant ID (needed for later)
$script:TENANT_ID = az account show --query tenantId -o tsv
Write-Host "[OK] Logged in to subscription: $script:SUBSCRIPTION_ID`n" -ForegroundColor Green
