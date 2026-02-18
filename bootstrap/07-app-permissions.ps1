# ============================================================================
# Application Permissions
# ============================================================================

Write-Host "[6/9] Adding Application.Read.All permission..." -ForegroundColor Yellow
$EXISTING_PERM = az ad app permission list --id $script:APP_ID --query "[?resourceAppId=='00000003-0000-0000-c000-000000000000'].resourceAccess[?id=='9a5d68dd-52b0-4cc2-bd40-abcf44ac3a1c'].id" -o tsv

if ($EXISTING_PERM) {
    Write-Host "[OK] Permission already added`n" -ForegroundColor Green
} else {
    az ad app permission add `
        --id $script:APP_ID `
        --api 00000003-0000-0000-c000-000000000000 `
        --api-permissions 9a5d68dd-52b0-4cc2-bd40-abcf44ac3a1c=Role
    Write-Host "[OK] Permission added`n" -ForegroundColor Green
}

# Grant admin consent
Write-Host "[7/9] Granting admin consent..." -ForegroundColor Yellow
az ad app permission admin-consent --id $script:APP_ID
Write-Host "[OK] Admin consent granted`n" -ForegroundColor Green
