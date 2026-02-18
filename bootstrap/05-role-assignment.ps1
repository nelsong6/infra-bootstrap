# ============================================================================
# Role Assignment - Owner Role
# ============================================================================

Write-Host "[4/9] Granting Owner role to service principal..." -ForegroundColor Yellow
$EXISTING_ROLE = az role assignment list --assignee $script:SP_ID --role Owner --scope "/subscriptions/$script:SUBSCRIPTION_ID" --query "[0].id" -o tsv

if ($EXISTING_ROLE) {
    Write-Host "[OK] Owner role already assigned`n" -ForegroundColor Green
} else {
    az role assignment create `
        --assignee $script:SP_ID `
        --role Owner `
        --scope "/subscriptions/$script:SUBSCRIPTION_ID"
    Write-Host "[OK] Owner role assigned`n" -ForegroundColor Green
}
