# ============================================================================
# Bootstrap Summary
# Display final results and next steps
# ============================================================================

Write-Host "============================================" -ForegroundColor Green
Write-Host "✅ BOOTSTRAP COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "============================================`n" -ForegroundColor Green

Write-Host "Backend Configuration:" -ForegroundColor Cyan
Get-Content $script:TARGET_FILE | Write-Host -ForegroundColor Gray
Write-Host ""

Write-Host "================================================" -ForegroundColor Green
Write-Host "GitHub Repository Variables (Already Set):" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host "AZURE_CLIENT_ID       = $script:APP_ID" -ForegroundColor Yellow
Write-Host "AZURE_TENANT_ID       = $script:TENANT_ID" -ForegroundColor Yellow
Write-Host "AZURE_SUBSCRIPTION_ID = $script:SUBSCRIPTION_ID" -ForegroundColor Yellow
Write-Host "================================================`n" -ForegroundColor Green

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Commit the generated backend.tf file" -ForegroundColor White
Write-Host "2. Run: cd tofu; tofu init" -ForegroundColor White
Write-Host "3. Run: tofu plan" -ForegroundColor White
Write-Host "4. Deploy via GitHub Actions workflow`n" -ForegroundColor White
