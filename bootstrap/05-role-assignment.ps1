# ============================================================================
# Role Assignment - Owner, App Configuration Data Owner, App Configuration Data Reader, Key Vault Administrator
# ============================================================================

# Resolve SP_ID from Azure if the previous step didn't set it
if (-not $script:SP_ID) {
    $script:SP_ID = az ad sp list --filter "appId eq '$script:APP_ID'" --query "[0].id" -o tsv
    if (-not $script:SP_ID) { throw "Service principal for client ID '$script:APP_ID' not found. Run step 04 first." }
}

$_scope = "/subscriptions/$script:SUBSCRIPTION_ID"

Write-Host "[4/9] Granting Owner role to service principal..." -ForegroundColor Yellow
$EXISTING_ROLE = az role assignment list --assignee $script:SP_ID --role Owner --scope $_scope --query "[0].id" -o tsv

if ($EXISTING_ROLE) {
    Write-Host "[OK] Owner role already assigned`n" -ForegroundColor Green
} else {
    az role assignment create `
        --assignee $script:SP_ID `
        --role Owner `
        --scope $_scope
    Write-Host "[OK] Owner role assigned`n" -ForegroundColor Green
}

Write-Host "[4/9] Granting App Configuration Data Owner role to service principal..." -ForegroundColor Yellow
$EXISTING_APPCONFIG_OWNER = az role assignment list --assignee $script:SP_ID --role "App Configuration Data Owner" --scope $_scope --query "[0].id" -o tsv

if ($EXISTING_APPCONFIG_OWNER) {
    Write-Host "[OK] App Configuration Data Owner role already assigned`n" -ForegroundColor Green
} else {
    az role assignment create `
        --assignee $script:SP_ID `
        --role "App Configuration Data Owner" `
        --scope $_scope
    Write-Host "[OK] App Configuration Data Owner role assigned`n" -ForegroundColor Green
}

Write-Host "[4/9] Granting App Configuration Data Reader role to service principal..." -ForegroundColor Yellow
$EXISTING_APPCONFIG_READER = az role assignment list --assignee $script:SP_ID --role "App Configuration Data Reader" --scope $_scope --query "[0].id" -o tsv

if ($EXISTING_APPCONFIG_READER) {
    Write-Host "[OK] App Configuration Data Reader role already assigned`n" -ForegroundColor Green
} else {
    az role assignment create `
        --assignee $script:SP_ID `
        --role "App Configuration Data Reader" `
        --scope $_scope
    Write-Host "[OK] App Configuration Data Reader role assigned`n" -ForegroundColor Green
}

Write-Host "[4/9] Granting Key Vault Administrator role to service principal..." -ForegroundColor Yellow
$EXISTING_KV_ADMINISTRATOR = az role assignment list --assignee $script:SP_ID --role "Key Vault Administrator" --scope $_scope --query "[0].id" -o tsv

if ($EXISTING_KV_ADMINISTRATOR) {
    Write-Host "[OK] Key Vault Administrator role already assigned`n" -ForegroundColor Green
} else {
    az role assignment create `
        --assignee $script:SP_ID `
        --role "Key Vault Administrator" `
        --scope $_scope
    Write-Host "[OK] Key Vault Administrator role assigned`n" -ForegroundColor Green
}
