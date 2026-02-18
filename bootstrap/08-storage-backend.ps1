# ============================================================================
# Azure Storage Backend for OpenTofu State
# ============================================================================

Write-Host "[8/9] Setting up Azure Storage for OpenTofu state..." -ForegroundColor Yellow

# Check if tfstate resource group exists (temporarily disable error handling for the check)
$PreviousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$EXISTING_TFSTATE_RG = az group show --name $script:TFSTATE_RG_NAME --query id -o tsv 2>$null
$ErrorActionPreference = $PreviousErrorActionPreference

if ($EXISTING_TFSTATE_RG) {
    Write-Host "  Resource group '$script:TFSTATE_RG_NAME' already exists" -ForegroundColor Gray
    # Get existing storage account if it exists
    $EXISTING_STORAGE = az storage account list --resource-group $script:TFSTATE_RG_NAME --query "[0].name" -o tsv
    if ($EXISTING_STORAGE) {
        $script:STORAGE_NAME = $EXISTING_STORAGE
        Write-Host "  Using existing storage account: $script:STORAGE_NAME" -ForegroundColor Gray
    }
} else {
    Write-Host "  Creating resource group '$script:TFSTATE_RG_NAME'..." -ForegroundColor Gray
    az group create --name $script:TFSTATE_RG_NAME --location westus2 --output none
}

# Check if storage account exists (temporarily disable error handling for the check)
$ErrorActionPreference = "Continue"
$STORAGE_EXISTS = az storage account show --name $script:STORAGE_NAME --resource-group $script:TFSTATE_RG_NAME --query id -o tsv 2>$null
$ErrorActionPreference = $PreviousErrorActionPreference

if (-not $STORAGE_EXISTS) {
    Write-Host "  Creating storage account: $script:STORAGE_NAME..." -ForegroundColor Gray
    az storage account create `
        --resource-group $script:TFSTATE_RG_NAME `
        --name $script:STORAGE_NAME `
        --sku Standard_LRS `
        --encryption-services blob `
        --output none
}

# Check if container exists
$CONTAINER_EXISTS = az storage container exists `
    --name $script:CONTAINER_NAME `
    --account-name $script:STORAGE_NAME `
    --query exists -o tsv

if ($CONTAINER_EXISTS -eq "true") {
    Write-Host "  Container '$script:CONTAINER_NAME' already exists" -ForegroundColor Gray
} else {
    Write-Host "  Creating blob container: $script:CONTAINER_NAME..." -ForegroundColor Gray
    az storage container create `
        --name $script:CONTAINER_NAME `
        --account-name $script:STORAGE_NAME `
        --output none
}

Write-Host "[OK] Storage backend configured`n" -ForegroundColor Green
