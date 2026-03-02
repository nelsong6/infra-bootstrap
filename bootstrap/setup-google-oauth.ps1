# ============================================================================
# Setup Google OAuth for "Sign in with Google"
# ============================================================================
# Google OAuth credentials must be created manually in the GCP Console
# (the IAP API approach requires an organization). This script guides
# you through the process and stores the credentials in Azure Key Vault.
#
# Prerequisites:
#   - az CLI authenticated (`az login`)
#   - local.config populated (for Key Vault name)
#   - A Google Cloud project with OAuth consent screen configured
#
# Usage:
#   cd infra-bootstrap
#   .\bootstrap\setup-google-oauth.ps1

$ErrorActionPreference = "Stop"

# ── Load config ─────────────────────────────────────────────────────
$localConfig = Join-Path $PSScriptRoot "local.config"
if (-not (Test-Path $localConfig)) {
    throw "local.config not found. Copy local.config.example and fill in your values."
}

function _ParseIniConfig($path) {
    $result  = @{}
    $section = ""
    foreach ($line in (Get-Content $path)) {
        $line = $line.Trim()
        if ($line -match '^\[(.+)\]$')          { $section = $Matches[1].ToLower(); continue }
        if ($line -match '^#' -or $line -eq '')  { continue }
        if ($line -match '^(.+?)\s*=\s*(.*)$')   { $result["$section.$($Matches[1].Trim().ToLower())"] = $Matches[2].Trim() }
    }
    return $result
}

$cfg = _ParseIniConfig $localConfig

# Key Vault name — same derivation as 01-config.ps1
if ($cfg["azure.keyvault_name"] -and $cfg["azure.keyvault_name"] -ne "") {
    $kvName = $cfg["azure.keyvault_name"]
} else {
    $folderName = Split-Path -Leaf (Split-Path $PSScriptRoot -Parent)
    $kvName = ($folderName.ToLower() -replace '[^a-z0-9]', '-') -replace '-+', '-' -replace '^-|-$', ''
    if ($kvName -notmatch '^[a-z]') { $kvName = "kv-" + $kvName }
    if ($kvName.Length -gt 24)      { $kvName = $kvName.Substring(0, 24).TrimEnd('-') }
}

Write-Host "Using Key Vault: $kvName" -ForegroundColor Gray

# ── Skip if secrets already exist ─────────────────────────────────
$existingClientId = try { az keyvault secret show --vault-name $kvName --name "google-oauth-client-id" --query "value" -o tsv 2>$null } catch { $null }
if ($existingClientId) {
    Write-Host "[OK] Google OAuth secrets already exist in Key Vault -- skipping" -ForegroundColor Green
    return
}

# ── Guide the user ────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Google OAuth Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Create a Google OAuth 2.0 client in the GCP Console:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Go to: https://console.cloud.google.com/apis/credentials" -ForegroundColor White
Write-Host "  2. Configure the OAuth consent screen if not already done" -ForegroundColor White
Write-Host "  3. Click 'Create Credentials' > 'OAuth client ID'" -ForegroundColor White
Write-Host "  4. Application type: 'Web application'" -ForegroundColor White
Write-Host "  5. Name: 'romaine.life - Sign in with Google'" -ForegroundColor White
Write-Host "  6. Authorized redirect URIs:" -ForegroundColor White
Write-Host "     - https://homepage.api.romaine.life/auth/google/callback" -ForegroundColor Gray
Write-Host "     - https://<container-app-default-hostname>/auth/google/callback" -ForegroundColor Gray
Write-Host "       (find via: az containerapp show -n homepage-api -g <rg> --query 'properties.configuration.ingress.fqdn' -o tsv)" -ForegroundColor DarkGray
Write-Host "     - http://localhost:3000/auth/google/callback" -ForegroundColor Gray
Write-Host "  7. Click 'Create' and copy the Client ID and Client Secret" -ForegroundColor White
Write-Host ""

$clientId = Read-Host "Enter Google OAuth Client ID"
if (-not $clientId) { throw "Client ID is required." }

$clientSecret = Read-Host "Enter Google OAuth Client Secret"
if (-not $clientSecret) { throw "Client Secret is required." }

# ── Store in Key Vault ──────────────────────────────────────────────
Write-Host "Storing credentials in Key Vault '$kvName'..." -ForegroundColor Gray

az keyvault secret set --vault-name $kvName --name "google-oauth-client-id" --value $clientId | Out-Null
az keyvault secret set --vault-name $kvName --name "google-oauth-client-secret" --value $clientSecret | Out-Null

Write-Host ""
Write-Host "Done! Secrets stored:" -ForegroundColor Green
Write-Host "  google-oauth-client-id" -ForegroundColor Gray
Write-Host "  google-oauth-client-secret" -ForegroundColor Gray
