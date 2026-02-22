# ============================================================================
# Configuration
# ============================================================================

# ------------------------------------------------------------------
# Load local.config (gitignored, user-specific values)
# ------------------------------------------------------------------
$_localConfigPath = "$PSScriptRoot\local.config"

# Parse an INI-style config file into a flat hashtable keyed as "section.key"
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

$_cfg = _ParseIniConfig $_localConfigPath

# Validate required keys (github.repo is optional — inferred from git if absent)
$_required = @(
    "azure.subscription_id",
    "azure.application_id",
    "spacelift.hostname"
)
$_missing = $_required | Where-Object { -not $_cfg.ContainsKey($_) -or $_cfg[$_] -eq "" }
if ($_missing) {
    throw "local.config is missing required values:`n  $($_missing -join "`n  ")`nSee local.config.example for reference."
}

# ------------------------------------------------------------------
# User-specific values (sourced from local.config)
# ------------------------------------------------------------------
$script:SUBSCRIPTION_ID    = $_cfg["azure.subscription_id"]
$script:APP_ID             = $_cfg["azure.application_id"]
$script:SPACELIFT_HOSTNAME = $_cfg["spacelift.hostname"]

# Resolve GitHub repo — prefer local.config override, otherwise infer from git remote
if ($_cfg["github.repo"] -and $_cfg["github.repo"] -ne "") {
    $script:REPO = $_cfg["github.repo"]
    Write-Host "  Repo (local.config):  $script:REPO" -ForegroundColor Gray
} else {
    $_remoteUrl = git remote get-url origin 2>$null
    if (-not $_remoteUrl) {
        throw "Could not determine repo: 'git remote get-url origin' failed and github.repo is not set in local.config."
    }
    # Parse both HTTPS (https://github.com/owner/repo[.git]) and SSH (git@github.com:owner/repo[.git])
    if ($_remoteUrl -match 'github\.com[:/](.+?/[^/]+?)(?:\.git)?$') {
        $script:REPO = $Matches[1]
        Write-Host "  Repo (git remote):    $script:REPO" -ForegroundColor Gray
    } else {
        throw "Could not parse owner/repo from remote URL: $_remoteUrl`nSet github.repo manually in local.config."
    }
}
$script:SPACELIFT_SPACE_ID = if ($_cfg["spacelift.space_id"]) { $_cfg["spacelift.space_id"] } else { "root" }

# ------------------------------------------------------------------
# Static / derived values (safe to commit)
# ------------------------------------------------------------------
$script:TFSTATE_RG_NAME = "infra"
$script:STORAGE_NAME    = "tfstate" + (Get-Random -Minimum 1000 -Maximum 9999)
$script:CONTAINER_NAME  = "tfstate"
$script:TARGET_FILE     = "tofu/backend.tf"

# Key Vault name — derived from folder name, max 24 chars, must start with a letter
$_folderName = Split-Path -Leaf (Get-Location)
$_kvName = ($_folderName.ToLower() -replace '[^a-z0-9]', '-') -replace '-+', '-' -replace '^-|-$', ''
if ($_kvName -notmatch '^[a-z]') { $_kvName = "kv-" + $_kvName }
if ($_kvName.Length -gt 24)      { $_kvName = $_kvName.Substring(0, 24).TrimEnd('-') }
$script:KEYVAULT_NAME = $_kvName

# Spacelift stack slug — same rules as KV name (no length cap)
$_stackSlug = ($_folderName.ToLower() -replace '[^a-z0-9]', '-') -replace '-+', '-' -replace '^-|-$', ''
if ($_stackSlug -notmatch '^[a-z]') { $_stackSlug = "stack-" + $_stackSlug }
$script:SPACELIFT_STACK_SLUG = $_stackSlug

Write-Host "Configuration loaded" -ForegroundColor Gray
