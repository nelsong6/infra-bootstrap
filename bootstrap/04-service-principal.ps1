# ============================================================================
# Service Principal
# ============================================================================

Write-Host "[3/9] Checking for service principal..." -ForegroundColor Yellow
$EXISTING_SP_ID = az ad sp list --filter "appId eq '$script:APP_ID'" --query "[0].id" -o tsv

if ($EXISTING_SP_ID) {
    Write-Host "✓ Service principal already exists (ID: $EXISTING_SP_ID)`n" -ForegroundColor Green
    $script:SP_ID = $EXISTING_SP_ID
} else {
    Write-Host "  Creating service principal..." -ForegroundColor Gray
    $script:SP_ID = az ad sp create --id $script:APP_ID --query id -o tsv
    Write-Host "✓ Created service principal: $script:SP_ID`n" -ForegroundColor Green
}
