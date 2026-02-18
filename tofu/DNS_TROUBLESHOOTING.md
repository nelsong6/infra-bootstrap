# DNS Custom Domain Fix - Troubleshooting Guide

## 🔧 What Was Fixed

The custom domain setup was failing with two critical errors:

### Error 1: Static Web App CNAME Validation Failed
```
Error: CNAME Record is invalid. Please ensure the CNAME record has been created.
```

**Root Cause:** Azure was attempting to validate the custom domain immediately after creating the DNS records, before DNS had time to propagate.

**Fix Applied:**
- Added a `time_sleep` resource with a 90-second delay
- Updated dependencies to ensure the custom domain binding waits for DNS propagation

### Error 2: Container App TXT Record Missing
```
Error: A TXT record pointing from asuid.api.workout.romaine.life to 
20771354BF9C2292CB61D8B06CFA48504D60EA94671FBAAECF4BED25203808E1 was not found.
```

**Root Cause:** Azure Container Apps require a **TXT verification record** for custom domain validation. This was completely missing from the DNS configuration.

**Fix Applied:**
- Added `azurerm_dns_txt_record.backend_verification` resource
- Record name: `asuid.api.workout`
- Record value: Automatically pulled from `azurerm_container_app.workout_api.custom_domain_verification_id`

---

## 📋 Changes Made

### 1. Updated `tofu/dns.tf`

**Added TXT verification record:**
```hcl
resource "azurerm_dns_txt_record" "backend_verification" {
  name                = "asuid.api.workout"
  zone_name           = data.azurerm_dns_zone.romaine.name
  resource_group_name = data.azurerm_resource_group.workout.name
  ttl                 = 3600

  record {
    value = azurerm_container_app.workout_api.custom_domain_verification_id
  }
}
```

**Added DNS propagation delay:**
```hcl
resource "time_sleep" "wait_for_dns" {
  depends_on = [
    azurerm_dns_cname_record.frontend,
    azurerm_dns_cname_record.backend,
    azurerm_dns_txt_record.backend_verification
  ]

  create_duration = "90s"
}
```

**Updated custom domain resources to wait for DNS:**
- `azurerm_static_web_app_custom_domain.frontend` now depends on `time_sleep.wait_for_dns`
- `azurerm_container_app_custom_domain.backend` now depends on both TXT record and `time_sleep.wait_for_dns`

### 2. Updated `tofu/provider.tf`

**Added time provider:**
```hcl
time = {
  source  = "hashicorp/time"
  version = "~> 0.11"
}
```

---

## 🚀 How to Apply the Fix

### Step 1: Verify Prerequisites

Make sure you've completed the DNS bootstrap:

```powershell
cd tofu

# Check if DNS zone exists and nameservers are configured
.\bootstrap-dns.ps1
```

**Verify nameservers are updated at your domain registrar!**

### Step 2: Initialize New Provider

```powershell
tofu init -upgrade
```

This downloads the `hashicorp/time` provider.

### Step 3: Preview Changes

```powershell
tofu plan
```

**Expected new resources:**
- `azurerm_dns_txt_record.backend_verification` - TXT record for Container App verification
- `time_sleep.wait_for_dns` - 90-second delay for DNS propagation

**Expected updates:**
- Custom domain resources will show updated dependencies

### Step 4: Apply Configuration

```powershell
tofu apply
```

**What happens:**
1. ✅ Creates CNAME records for both frontend and backend
2. ✅ Creates TXT verification record for Container App
3. ⏱️ Waits 90 seconds for DNS propagation
4. ✅ Attempts to bind custom domains to Static Web App and Container App
5. ✅ Azure provisions SSL certificates (may take additional 5-15 minutes)

---

## 🧪 Testing

### 1. Verify DNS Records Created

```powershell
# Check CNAME records
nslookup -type=CNAME workout.romaine.life
nslookup -type=CNAME api.workout.romaine.life

# Check TXT verification record
nslookup -type=TXT asuid.api.workout.romaine.life
```

**Expected results:**
- `workout.romaine.life` → CNAME pointing to Static Web App hostname
- `api.workout.romaine.life` → CNAME pointing to Container App hostname  
- `asuid.api.workout.romaine.life` → TXT record with verification ID

### 2. Check Custom Domain Status

**Static Web App:**
```powershell
az staticwebapp show `
  --name workout-app-[suffix] `
  --resource-group workout-rg `
  --query "customDomains"
```

**Container App:**
```powershell
az containerapp hostname list `
  --name workout-api `
  --resource-group workout-rg `
  --output table
```

### 3. Test HTTPS Access

```powershell
# Test frontend (may take 5-15 min for SSL)
curl https://workout.romaine.life

# Test backend API
curl https://api.workout.romaine.life/health
```

---

## ⚠️ Common Issues After Apply

### Issue: SSL Certificate Still Provisioning

**Symptoms:**
- Browser shows "Your connection is not private"
- Certificate is self-signed

**Solution:**
- SSL provisioning takes 5-15 minutes after custom domain is bound
- Wait and refresh
- Check status with Azure CLI commands above

### Issue: DNS Changes Not Visible

**Symptoms:**
- `nslookup` still returns old/no results
- Online DNS checkers show propagation incomplete

**Solution:**
```powershell
# Clear local DNS cache
ipconfig /flushdns

# Check from different DNS server
nslookup workout.romaine.life 8.8.8.8
nslookup api.workout.romaine.life 8.8.8.8

# Wait longer - can take up to 48 hours (usually 1-2 hours)
```

### Issue: "Custom domain already exists" Error

**Symptoms:**
- Terraform fails saying custom domain is already attached

**Solution:**
```powershell
# Remove existing custom domains
az staticwebapp hostname delete `
  --name workout-app-[suffix] `
  --resource-group workout-rg `
  --hostname workout.romaine.life

az containerapp hostname delete `
  --name workout-api `
  --resource-group workout-rg `
  --hostname api.workout.romaine.life

# Re-run terraform
tofu apply
```

### Issue: TXT Record Validation Still Failing

**Symptoms:**
- Error still mentions TXT record not found

**Possible causes:**
1. DNS hasn't propagated (wait longer)
2. Verification ID changed

**Solution:**
```powershell
# Get the current verification ID
tofu output backend_verification_txt_record

# Verify it matches what's in DNS
nslookup -type=TXT asuid.api.workout.romaine.life

# If they don't match, the Container App was recreated
# Delete the custom domain and re-apply:
az containerapp hostname delete `
  --name workout-api `
  --resource-group workout-rg `
  --hostname api.workout.romaine.life

tofu apply
```

---

## 📚 Understanding the DNS Records

After successful deployment, you should have these DNS records in `romaine.life` zone:

| Record Type | Name | Value | Purpose |
|-------------|------|-------|---------|
| **CNAME** | `workout` | Static Web App hostname | Routes traffic to frontend |
| **CNAME** | `api.workout` | Container App hostname | Routes traffic to backend API |
| **TXT** | `asuid.api.workout` | Container App verification ID | Proves domain ownership |

The TXT record format `asuid.<subdomain>` is Azure's standard for Container App domain verification.

---

## 🔄 If You Need to Start Over

```powershell
# 1. Remove custom domain bindings
az staticwebapp hostname delete `
  --name workout-app-[suffix] `
  --resource-group workout-rg `
  --hostname workout.romaine.life

az containerapp hostname delete `
  --name workout-api `
  --resource-group workout-rg `
  --hostname api.workout.romaine.life

# 2. Remove DNS records from Terraform state
tofu state rm azurerm_dns_cname_record.frontend
tofu state rm azurerm_dns_cname_record.backend
tofu state rm azurerm_dns_txt_record.backend_verification
tofu state rm time_sleep.wait_for_dns
tofu state rm azurerm_static_web_app_custom_domain.frontend
tofu state rm azurerm_container_app_custom_domain.backend

# 3. Re-import and re-apply
tofu apply
```

---

## ✅ Success Criteria

Your custom domains are working correctly when:

1. ✅ DNS records resolve correctly via `nslookup`
2. ✅ Both domains show "Ready" status in Azure Portal
3. ✅ HTTPS access works without certificate warnings
4. ✅ Frontend can communicate with backend (no CORS errors)
5. ✅ Certificate is issued by "Microsoft Azure TLS Issuing CA"

---

## 📞 Quick Reference

**Initialize & Apply:**
```powershell
cd tofu
tofu init -upgrade
tofu plan
tofu apply
```

**Check DNS:**
```powershell
nslookup -type=CNAME workout.romaine.life
nslookup -type=CNAME api.workout.romaine.life
nslookup -type=TXT asuid.api.workout.romaine.life
```

**Test URLs:**
```powershell
curl https://workout.romaine.life
curl https://api.workout.romaine.life/health
```

**View Logs:**
```powershell
az containerapp logs show --name workout-api --resource-group workout-rg --follow
```

---

**Need More Help?**
- See `CUSTOM_DOMAIN_SETUP.md` for detailed setup instructions
- Check Azure Portal for resource status
- Review Terraform plan output for expected changes
