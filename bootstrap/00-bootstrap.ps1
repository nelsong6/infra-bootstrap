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
    # Pre-flight: ensure local.config exists before running any steps
    $localConfig = Join-Path $PSScriptRoot "local.config"
    if (-not (Test-Path $localConfig)) {
        throw "local.config not found.`nCopy bootstrap\local.config.example to bootstrap\local.config and fill in your values."
    }

    $steps = Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" |
             Where-Object { $_.Name -ne "00-bootstrap.ps1" } |
             Sort-Object Name

    foreach ($step in $steps) {
        . $step.FullName
    }

} catch {
    Write-Host "`n❌ ERROR: Bootstrap failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
