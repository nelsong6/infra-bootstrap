# ============================================================================
# Key Vault - Create shared Key Vault for storing secrets
# ============================================================================

$_location = az group show --name $script:TFSTATE_RG_NAME --query location -o tsv

Write-Host "[5/9] Creating Key Vault '$script:KEYVAULT_NAME'..." -ForegroundColor Yellow
$EXISTING_KV = try { az keyvault show --name $script:KEYVAULT_NAME --resource-group $script:TFSTATE_RG_NAME --query name -o tsv 2>$null } catch { $null }

if ($EXISTING_KV) {
    Write-Host "[OK] Key Vault '$script:KEYVAULT_NAME' already exists`n" -ForegroundColor Green
} else {
    az keyvault create `
        --name $script:KEYVAULT_NAME `
        --resource-group $script:TFSTATE_RG_NAME `
        --location $_location `
        --enable-rbac-authorization true `
        --retention-days 7 `
        --no-self-perms `
        | Out-Null
    Write-Host "[OK] Key Vault '$script:KEYVAULT_NAME' created`n" -ForegroundColor Green
}
