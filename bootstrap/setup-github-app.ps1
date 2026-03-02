# ============================================================================
# Setup GitHub App for OAuth Login
# ============================================================================
# Creates a GitHub App via the manifest flow and stores its credentials
# in Azure Key Vault. GitHub Apps support multiple callback URLs and use
# the same OAuth endpoints as OAuth Apps, so passport-github2 works unchanged.
#
# Prerequisites:
#   - az CLI authenticated (`az login`)
#   - local.config populated (for Key Vault name)
#
# Usage:
#   cd infra-bootstrap
#   .\bootstrap\setup-github-app.ps1

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
$existingClientId = az keyvault secret show --vault-name $kvName --name "github-oauth-client-id" --query "value" -o tsv 2>$null
if ($existingClientId) {
    Write-Host "[OK] GitHub OAuth secrets already exist in Key Vault -- skipping app creation" -ForegroundColor Green
    return
}

# ── Pick a random available port ──────────────────────────────────
$tcpListener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
$tcpListener.Start()
$port = $tcpListener.LocalEndpoint.Port
$tcpListener.Stop()

$callbackUrl = "http://localhost:$port/callback"

# ── Define the GitHub App manifest ──────────────────────────────────
$manifest = @{
    name           = "romaine-life-login"
    url            = "https://romaine.life"
    callback_urls  = @(
        "https://homepage.api.romaine.life/auth/github/callback",
        "http://localhost:3000/auth/github/callback"
    )
    redirect_url   = $callbackUrl
    public         = $false
    default_permissions = @{}
} | ConvertTo-Json -Compress

# Escape single quotes for HTML embedding
$manifestEscaped = $manifest -replace "'", "&#39;"

# ── Create temp HTML with auto-submitting form ──────────────────────
$html = @"
<!DOCTYPE html>
<html><body>
<p>Redirecting to GitHub to create the app...</p>
<form id="f" action="https://github.com/settings/apps/new" method="post">
<input type="hidden" name="manifest" value='$manifestEscaped'>
</form>
<script>document.getElementById('f').submit();</script>
</body></html>
"@

$tempFile = Join-Path $env:TEMP "github-app-manifest.html"
$html | Out-File -FilePath $tempFile -Encoding UTF8

# ── Start HTTP listener for callback ────────────────────────────────
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

try {
    Write-Host ""
    Write-Host "Opening browser -- click 'Create GitHub App' on the GitHub page." -ForegroundColor Yellow
    Write-Host "Listening on port $port for callback..." -ForegroundColor Gray
    Start-Process $tempFile

    # ── Wait for GitHub redirect (with code) ──────────────────────────
    # Loop until we get a request with a ?code= parameter (skip favicon etc.)
    $code = $null
    while (-not $code) {
        $context = $listener.GetContext()
        $code = $context.Request.QueryString["code"]

        if (-not $code) {
            # Not the callback we want -- send empty response and keep waiting
            $context.Response.StatusCode = 204
            $context.Response.Close()
            continue
        }

        # Send success page to browser
        $responseHtml = "<html><body><h2>GitHub App created. You can close this tab.</h2></body></html>"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseHtml)
        $context.Response.ContentType = "text/html"
        $context.Response.ContentLength64 = $buffer.Length
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        $context.Response.Close()
    }
} finally {
    $listener.Stop()
    $listener.Close()
}

# ── Exchange code for app credentials ───────────────────────────────
# NOTE: This endpoint must be called WITHOUT an Authorization header.
# Using gh api would send one automatically and cause a 404.
Write-Host "Exchanging code for credentials..." -ForegroundColor Gray
$result = Invoke-RestMethod -Method POST -Uri "https://api.github.com/app-manifests/$code/conversions" -ContentType "application/json"

$clientId     = $result.client_id
$clientSecret = $result.client_secret

if (-not $clientId -or -not $clientSecret) {
    throw "Failed to get client_id or client_secret from GitHub response."
}

Write-Host "GitHub App '$($result.name)' created (ID: $($result.id))" -ForegroundColor Green

# ── Store in Key Vault ──────────────────────────────────────────────
Write-Host "Storing credentials in Key Vault '$kvName'..." -ForegroundColor Gray

az keyvault secret set --vault-name $kvName --name "github-oauth-client-id" --value $clientId | Out-Null
az keyvault secret set --vault-name $kvName --name "github-oauth-client-secret" --value $clientSecret | Out-Null

Write-Host ""
Write-Host "Done! Secrets stored:" -ForegroundColor Green
Write-Host "  github-oauth-client-id" -ForegroundColor Gray
Write-Host "  github-oauth-client-secret" -ForegroundColor Gray

# Clean up
Remove-Item $tempFile -ErrorAction SilentlyContinue
