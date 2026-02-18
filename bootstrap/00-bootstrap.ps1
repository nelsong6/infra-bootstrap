# ============================================================================
# OpenTofu Bootstrap Script - Main Entry Point
# Creates Azure AD App Registration with OIDC for GitHub Actions
# ============================================================================

# Enable strict error handling
$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "OpenTofu Bootstrap - Azure OIDC Setup" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

try {
    # Execute each section in order
    . "$PSScriptRoot\01-config.ps1"
    . "$PSScriptRoot\02-azure-login.ps1"
    . "$PSScriptRoot\03-app-registration.ps1"
    . "$PSScriptRoot\04-service-principal.ps1"
    . "$PSScriptRoot\05-role-assignment.ps1"
    . "$PSScriptRoot\06-federated-credentials.ps1"
    . "$PSScriptRoot\07-app-permissions.ps1"
    . "$PSScriptRoot\08-storage-backend.ps1"
    . "$PSScriptRoot\12-generate-backend.ps1"
    . "$PSScriptRoot\13-summary.ps1"

} catch {
    Write-Host "`n❌ ERROR: Bootstrap failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
