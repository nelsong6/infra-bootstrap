# ============================================================================
# Setup Google Cloud Workload Identity Federation for Spacelift
# ============================================================================
# Creates a GCP Workload Identity Pool + Provider so Spacelift can authenticate
# via OIDC — no stored credentials. Also creates a service account with
# roles/iap.admin so Terraform can manage Google OAuth clients.
#
# Prerequisites:
#   - gcloud CLI authenticated (`gcloud auth login`)
#   - az CLI authenticated (`az login`) — only for printing next steps
#   - local.config populated (for Spacelift hostname)
#   - A Google Cloud project (created manually or via `gcloud projects create`)
#
# Usage:
#   cd infra-bootstrap
#   .\bootstrap\setup-google-cloud.ps1 -ProjectId "your-gcp-project-id"

param(
    [Parameter(Mandatory = $false)]
    [string]$ProjectId
)

$ErrorActionPreference = "Stop"

# Helper: gcloud.ps1 writes status messages to the PS error stream, which
# triggers $ErrorActionPreference="Stop" even on success.  Run gcloud with
# relaxed error preference and fail on non-zero exit code instead.
function _Invoke-Gcloud {
    $ErrorActionPreference = "Continue"
    $result = gcloud @args 2>$null
    if ($LASTEXITCODE -ne 0) { throw "gcloud failed (exit $LASTEXITCODE): gcloud $($args -join ' ')" }
    return $result
}

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

$spaceliftHostname = $cfg["spacelift.hostname"]
if (-not $spaceliftHostname) {
    throw "spacelift.hostname not found in local.config."
}

# Resolve project ID: param > local.config > prompt
if (-not $ProjectId) {
    $ProjectId = $cfg["google.project_id"]
}
if (-not $ProjectId) {
    $ProjectId = Read-Host "Enter your Google Cloud project ID"
}
if (-not $ProjectId) {
    throw "Google Cloud project ID is required."
}

$poolId       = "spacelift-pool"
$providerId   = "spacelift-oidc"
$saName       = "spacelift-iap"
$saEmail      = "$saName@$ProjectId.iam.gserviceaccount.com"
$issuerUri    = "https://$spaceliftHostname"

Write-Host ""
Write-Host "Google Cloud OIDC Setup for Spacelift" -ForegroundColor Cyan
Write-Host "  Project:    $ProjectId" -ForegroundColor Gray
Write-Host "  Issuer:     $issuerUri" -ForegroundColor Gray
Write-Host ""

# ── Enable required APIs ────────────────────────────────────────────
Write-Host "[1/6] Enabling APIs..." -ForegroundColor Yellow
$apis = @(
    "iap.googleapis.com",
    "iam.googleapis.com",
    "sts.googleapis.com",
    "iamcredentials.googleapis.com"
)
foreach ($api in $apis) {
    _Invoke-Gcloud services enable $api --project $ProjectId --quiet
}
Write-Host "[OK] APIs enabled" -ForegroundColor Green

# ── Create Workload Identity Pool ───────────────────────────────────
Write-Host "[2/6] Creating Workload Identity Pool '$poolId'..." -ForegroundColor Yellow
$existingPool = try { _Invoke-Gcloud iam workload-identity-pools describe $poolId --location global --project $ProjectId --format "value(name)" } catch { $null }
if ($existingPool) {
    Write-Host "[OK] Pool already exists" -ForegroundColor Green
} else {
    _Invoke-Gcloud iam workload-identity-pools create $poolId `
        --location global `
        --display-name "Spacelift OIDC Pool" `
        --project $ProjectId
    Write-Host "[OK] Pool created" -ForegroundColor Green
}

# ── Create Workload Identity Provider ───────────────────────────────
Write-Host "[3/6] Creating OIDC Provider '$providerId'..." -ForegroundColor Yellow
$existingProvider = try { _Invoke-Gcloud iam workload-identity-pools providers describe $providerId `
    --workload-identity-pool $poolId --location global --project $ProjectId --format "value(name)" } catch { $null }
if ($existingProvider) {
    Write-Host "[OK] Provider already exists" -ForegroundColor Green
} else {
    _Invoke-Gcloud iam workload-identity-pools providers create-oidc $providerId `
        --workload-identity-pool $poolId `
        --location global `
        --issuer-uri $issuerUri `
        --attribute-mapping "google.subject=assertion.sub" `
        --project $ProjectId
    Write-Host "[OK] Provider created" -ForegroundColor Green
}

# ── Create service account ──────────────────────────────────────────
Write-Host "[4/6] Creating service account '$saName'..." -ForegroundColor Yellow
$existingSa = try { _Invoke-Gcloud iam service-accounts describe $saEmail --project $ProjectId --format "value(email)" } catch { $null }
if ($existingSa) {
    Write-Host "[OK] Service account already exists" -ForegroundColor Green
} else {
    _Invoke-Gcloud iam service-accounts create $saName `
        --display-name "Spacelift IAP Admin" `
        --project $ProjectId
    Write-Host "[OK] Service account created" -ForegroundColor Green
}

# ── Grant IAP Admin role ────────────────────────────────────────────
Write-Host "[5/6] Granting roles/iap.admin..." -ForegroundColor Yellow
_Invoke-Gcloud projects add-iam-policy-binding $ProjectId `
    --member "serviceAccount:$saEmail" `
    --role "roles/iap.admin" `
    --condition "None" `
    --quiet | Out-Null
Write-Host "[OK] Role granted" -ForegroundColor Green

# ── Bind pool to service account ────────────────────────────────────
Write-Host "[6/6] Binding Workload Identity Pool to service account..." -ForegroundColor Yellow
$projectNumber = _Invoke-Gcloud projects describe $ProjectId --format "value(projectNumber)"
$poolMember = "principalSet://iam.googleapis.com/projects/$projectNumber/locations/global/workloadIdentityPools/$poolId/*"

_Invoke-Gcloud iam service-accounts add-iam-policy-binding $saEmail `
    --role "roles/iam.workloadIdentityUser" `
    --member $poolMember `
    --project $ProjectId `
    --quiet | Out-Null
Write-Host "[OK] Binding created" -ForegroundColor Green

# ── Print Spacelift configuration ───────────────────────────────────
$providerResourceName = "projects/$projectNumber/locations/global/workloadIdentityPools/$poolId/providers/$providerId"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Setup complete! Configure these in Spacelift:" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Environment variables for the infra-bootstrap stack:" -ForegroundColor Yellow
Write-Host "  TF_VAR_google_project_id     = $ProjectId"
Write-Host "  TF_VAR_google_support_email  = <your-email>"
Write-Host ""
Write-Host "OIDC integration (Spacelift stack settings > Integrations > GCP):" -ForegroundColor Yellow
Write-Host "  Project Number:               $projectNumber"
Write-Host "  Service Account Email:         $saEmail"
Write-Host "  Workload Identity Provider:    $providerResourceName"
Write-Host ""
