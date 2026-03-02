# ============================================================================
# Bootstrap Summary
# Display final results and next steps
# ============================================================================

if (-not $script:TENANT_ID) {
    $script:TENANT_ID = az account show --query tenantId -o tsv
}

Write-Host "============================================" -ForegroundColor Green
Write-Host "✅ BOOTSTRAP COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "Spacelift Stack:" -ForegroundColor Cyan
Write-Host "  Hostname: $script:SPACELIFT_HOSTNAME" -ForegroundColor Gray
Write-Host "  Space:    $script:SPACELIFT_SPACE_ID" -ForegroundColor Gray
Write-Host "  Stack:    $script:SPACELIFT_STACK_SLUG" -ForegroundColor Gray
Write-Host ""
Write-Host "  Azure integration environment variables for your Spacelift stack:" -ForegroundColor Gray
Write-Host "    ARM_CLIENT_ID       = $script:APP_ID" -ForegroundColor Yellow
Write-Host "    ARM_TENANT_ID       = $script:TENANT_ID" -ForegroundColor Yellow
Write-Host "    ARM_SUBSCRIPTION_ID = $script:SUBSCRIPTION_ID" -ForegroundColor Yellow
Write-Host "    ARM_USE_OIDC        = true" -ForegroundColor Yellow
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run: cd tofu; tofu init" -ForegroundColor White
Write-Host "2. Run: tofu plan" -ForegroundColor White
Write-Host "3. Trigger a run from the Spacelift stack`n" -ForegroundColor White
