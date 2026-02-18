# CORS Configuration for Azure Container Apps

## Overview

CORS (Cross-Origin Resource Sharing) configuration for Azure Container Apps is **not yet available** in the Terraform AzureRM provider (as of v4.60.0), even though Azure Container Apps natively supports CORS policies.

## Why Not in Terraform?

While we upgraded to `azurerm` v4.60.0, the provider's `azurerm_container_app` resource does not expose a `cors_policy` block within the `ingress` configuration. This is a limitation of the Terraform provider, not Azure itself.

## Solution: Azure CLI

We've created a PowerShell script to configure CORS using Azure CLI after Terraform deployment.

### Usage

After deploying infrastructure with Terraform/OpenTofu:

```powershell
# Run from the tofu directory
cd tofu
.\configure-cors.ps1
```

This script will:
1. Fetch your Static Web App URL automatically
2. Configure CORS for the Container App backend API
3. Allow origins from:
   - Production frontend (Static Web App)
   - Local development (Vite dev server on port 5173)
   - Local preview (Vite preview on port 4173)

### Manual Configuration (Alternative)

You can also configure CORS manually using Azure CLI:

```bash
az containerapp ingress cors enable \
  --name workout-api \
  --resource-group workout-rg \
  --allowed-origins https://YOUR-STATIC-WEB-APP.azurestaticapps.net http://localhost:5173 \
  --allowed-methods GET POST PUT DELETE OPTIONS PATCH \
  --allowed-headers "*" \
  --expose-headers "*" \
  --allow-credentials true \
  --max-age 3600
```

Or via Azure Portal:
1. Navigate to Azure Portal
2. Go to your Container App (workout-api)
3. Select **CORS** under Settings
4. Add allowed origins
5. Save changes

## Current State

- ✅ azurerm provider upgraded to v4.60.0
- ✅ azuread provider upgraded to v3.7.0
- ✅ Terraform configuration is valid
- ⚠️ CORS must be configured via Azure CLI or Portal (post-deployment)

## Future Considerations

When the Terraform AzureRM provider adds native CORS support for Container Apps, we can migrate the configuration to Terraform. Monitor these resources:

- [AzureRM Provider Issues](https://github.com/hashicorp/terraform-provider-azurerm/issues)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/cors)

## Application-Level CORS

Your Express backend (backend/server.js) also has CORS middleware configured. This provides a **defense-in-depth** approach:

1. **Azure Container Apps CORS** - First line of defense at the infrastructure level
2. **Express CORS Middleware** - Second line of defense at the application level

Both should be configured with the same allowed origins for consistency.
