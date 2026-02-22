# ============================================================================
# One-off: Migrate OpenTofu state from Azure Blob Storage to Spacelift
# ============================================================================
#
# Run this once after the Spacelift stack exists.
# Downloads the current state from Azure and uploads it to Spacelift's
# state store via the GraphQL API.
#
# Prerequisites:
#   - Logged in to Azure CLI with access to the storage account
#   - bootstrap\api-key-bootstrap.config exists with Spacelift API key credentials
#   - bootstrap\01-config.ps1 is filled in (spacelift.hostname, stack slug)
# ============================================================================

$ErrorActionPreference = "Stop"

# Load shared config (sets SPACELIFT_HOSTNAME, SPACELIFT_STACK_SLUG, etc.)
. "$PSScriptRoot\01-config.ps1"

$_stateFile = Join-Path $PSScriptRoot "temp_migrate_state.json"

try {
    # ------------------------------------------------------------------
    # Download state from Azure Blob Storage
    # ------------------------------------------------------------------
    Write-Host "Downloading state from Azure Blob Storage..." -ForegroundColor Yellow

    az storage blob download `
        --account-name "tfstate6792" `
        --container-name "tfstate" `
        --name "infra.tfstate" `
        --file $_stateFile `
        --auth-mode login `
        --output none

    if ($LASTEXITCODE -ne 0) { throw "az storage blob download failed." }

    # CRITICAL FIX 1: Read the file as a single raw string, ensuring UTF-8 encoding
    $_stateContent = Get-Content $_stateFile -Raw -Encoding UTF8
    if (-not $_stateContent) { throw "Downloaded state file is empty." }

    Write-Host "  Downloaded ($([math]::Round($_stateContent.Length / 1KB, 1)) KB)" -ForegroundColor Gray

    # ------------------------------------------------------------------
    # Load Spacelift API credentials
    # ------------------------------------------------------------------
    $_configPath = "$PSScriptRoot\api-key-bootstrap.config"
    if (-not (Test-Path $_configPath)) {
        throw "Spacelift config not found: $_configPath"
    }

    $_apiKeyId = $null
    $_apiKeySecret = $null

    # CRITICAL FIX 2: Relaxed regex parsing to handle quotes and missing blocks
    foreach ($_line in (Get-Content $_configPath)) {
        $_line = $_line.Trim()
        
        if ($_line -match '^#' -or $_line -eq '') { continue }

        if ($_line -match '^api_key_id\s*=\s*"?([^"]+)"?$') { 
            $_apiKeyId = $Matches[1].Trim() 
        }
        
        if ($_line -match '^api_key_secret\s*=\s*"?([^"]+)"?$') { 
            $_apiKeySecret = $Matches[1].Trim() 
        }
    }

    if (-not $_apiKeyId -or -not $_apiKeySecret) {
        throw "Could not read api_key_id / api_key_secret from $_configPath"
    }

    # ------------------------------------------------------------------
    # Authenticate to Spacelift
    # ------------------------------------------------------------------
    $_apiUrl = "https://$script:SPACELIFT_HOSTNAME/graphql"
    Write-Host "Authenticating to Spacelift ($script:SPACELIFT_HOSTNAME)..." -ForegroundColor Yellow

    $_tokenResp = Invoke-RestMethod -Uri $_apiUrl -Method Post -ContentType "application/json" -Body (@{
        query     = 'mutation($id: ID!, $secret: String!) { apiKeyUser(id: $id, secret: $secret) { jwt } }'
        variables = @{ id = $_apiKeyId; secret = $_apiKeySecret }
    } | ConvertTo-Json -Depth 5)

    if (-not $_tokenResp.data.apiKeyUser.jwt) {
        throw "Failed to get Spacelift JWT. Check hostname and API key credentials."
    }
    $_authHeaders = @{ Authorization = "Bearer $($_tokenResp.data.apiKeyUser.jwt)" }
    Write-Host "  Authenticated as API key: $($_apiKeyId.Substring(0,8))..." -ForegroundColor Gray

    # ------------------------------------------------------------------
    # Upload state to Spacelift
    # ------------------------------------------------------------------
    Write-Host "Uploading state to Spacelift stack '$script:SPACELIFT_STACK_SLUG'..." -ForegroundColor Yellow

    # CRITICAL FIX 3: Construct the JSON body manually to prevent PowerShell's 
    # ConvertTo-Json from choking on the massive embedded base64 string
    $_stateBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($_stateContent))
    
    $_mutationBody = @"
{
  "query": "mutation(`$stack: ID!, `$state: String!) { stackStateImport(id: `$stack, state: `$state) { id } }",
  "variables": {
    "stack": "$script:SPACELIFT_STACK_SLUG",
    "state": "$_stateBase64"
  }
}
"@

    $_uploadResp = Invoke-RestMethod -Uri $_apiUrl -Method Post -ContentType "application/json" -Headers $_authHeaders -Body $_mutationBody

    if ($_uploadResp.errors) {
        throw "State upload failed: $($_uploadResp.errors | ConvertTo-Json -Compress)"
    }

    Write-Host "[OK] State migrated to stack '$script:SPACELIFT_STACK_SLUG'`n" -ForegroundColor Green

    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Verify state in Spacelift UI: https://$script:SPACELIFT_HOSTNAME/stack/$script:SPACELIFT_STACK_SLUG" -ForegroundColor White
    Write-Host "  2. Remove the backend block from tofu/provider.tf (Spacelift manages state directly)" -ForegroundColor White

} finally {
    Remove-Item $_stateFile -ErrorAction SilentlyContinue
}