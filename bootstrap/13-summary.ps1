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

Write-Host "Azure:" -ForegroundColor Cyan
Write-Host "  ARM_CLIENT_ID       = $script:APP_ID" -ForegroundColor Yellow
Write-Host "  ARM_TENANT_ID       = $script:TENANT_ID" -ForegroundColor Yellow
Write-Host "  ARM_SUBSCRIPTION_ID = $script:SUBSCRIPTION_ID" -ForegroundColor Yellow
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run: cd tofu; tofu init" -ForegroundColor White
Write-Host "2. Run: tofu plan" -ForegroundColor White
Write-Host "3. Push to main to trigger the GitHub Actions workflow`n" -ForegroundColor White
