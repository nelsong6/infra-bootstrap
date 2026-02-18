# ============================================================================
# App Registration
# ============================================================================

Write-Host "[2/9] Checking for existing app registration..." -ForegroundColor Yellow
$EXISTING_APP_ID = az ad app list --display-name $script:APP_NAME --query "[0].appId" -o tsv

if ($EXISTING_APP_ID) {
    Write-Host "[OK] App registration '$script:APP_NAME' already exists (ID: $EXISTING_APP_ID)" -ForegroundColor Green
    Write-Host "  Using existing app registration...`n" -ForegroundColor Gray
    $script:APP_ID = $EXISTING_APP_ID
} else {
    Write-Host "  Creating new app registration..." -ForegroundColor Gray
    $script:APP_ID = az ad app create --display-name $script:APP_NAME --query appId -o tsv
    Write-Host "[OK] Created app registration: $script:APP_ID`n" -ForegroundColor Green
}
