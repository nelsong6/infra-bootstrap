# ============================================================================
# Federated Credentials - OIDC for GitHub Actions
# ============================================================================

# ------------------------------------------------------------------
# CREDENTIAL 1: Main Branch (For Plans)
# ------------------------------------------------------------------
Write-Host "[5/9] Creating federated credential for Main Branch..." -ForegroundColor Yellow
$CRED_NAME = "GitHub-Actions-Main-Branch"
$EXISTING_CRED = az ad app federated-credential list --id $script:APP_ID --query "[?name=='$CRED_NAME'].name" -o tsv

if ($EXISTING_CRED) {
    Write-Host "✓ Federated credential '$CRED_NAME' already exists`n" -ForegroundColor Green
} else {
    $credJson = @{
        name = $CRED_NAME
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$($script:REPO):ref:refs/heads/main"
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Depth 10

    $credFile = "temp_cred.json"
    $credJson | Out-File -FilePath $credFile -Encoding utf8
    
    az ad app federated-credential create --id $script:APP_ID --parameters "@$credFile"
    Remove-Item $credFile
    Write-Host "✓ Federated credential created for repo: $script:REPO (main branch)`n" -ForegroundColor Green
}

# ------------------------------------------------------------------
# CREDENTIAL 2: Production Environment (For Apply)
# ------------------------------------------------------------------
Write-Host "[5.5/9] Creating federated credential for Production Environment..." -ForegroundColor Yellow
$ENV_CRED_NAME = "GitHub-Actions-Production-Env"
$EXISTING_ENV_CRED = az ad app federated-credential list --id $script:APP_ID --query "[?name=='$ENV_CRED_NAME'].name" -o tsv

if ($EXISTING_ENV_CRED) {
    Write-Host "✓ Federated credential '$ENV_CRED_NAME' already exists`n" -ForegroundColor Green
} else {
    $envCredJson = @{
        name = $ENV_CRED_NAME
        issuer = "https://token.actions.githubusercontent.com"
        subject = "repo:$($script:REPO):environment:prod"
        audiences = @("api://AzureADTokenExchange")
    } | ConvertTo-Json -Depth 10

    $envCredFile = "temp_env_cred.json"
    $envCredJson | Out-File -FilePath $envCredFile -Encoding utf8
    
    az ad app federated-credential create --id $script:APP_ID --parameters "@$envCredFile"
    Remove-Item $envCredFile
    Write-Host "✓ Federated credential created for repo: $script:REPO (environment: prod)`n" -ForegroundColor Green
}
