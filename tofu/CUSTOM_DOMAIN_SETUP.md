# Custom Domain Setup Guide - workout.romaine.life

This guide walks you through setting up custom domains for the Workout Tracker app.

## 📋 Overview

**Custom Domains:**
- Frontend: `https://workout.romaine.life`
- Backend API: `https://api.workout.romaine.life`

**SSL Certificates:** Azure-managed (automatic, free)

**DNS Provider:** Azure DNS

## 🚀 Step-by-Step Setup

### Phase 1: Bootstrap DNS Zone

#### Step 1: Run the Bootstrap Script

```powershell
cd tofu
.\bootstrap-dns.ps1
```

This script will:
- ✅ Check if you're logged into Azure CLI
- ✅ Verify the resource group exists
- ✅ Create the `romaine.life` DNS zone (if it doesn't exist)
- ✅ Display the Azure nameservers you need to configure
- ✅ Save nameservers to `dns-nameservers.txt` for reference

**Example output:**
```
====================================================================
  IMPORTANT: Configure Your Domain Registrar
====================================================================

Go to your domain registrar and update the nameservers to:

  • ns1-01.azure-dns.com
  • ns2-01.azure-dns.net
  • ns3-01.azure-dns.org
  • ns4-01.azure-dns.info
```

#### Step 2: Update Domain Registrar

Go to your domain registrar (where you purchased `romaine.life`) and update the nameservers:

**Common Registrars:**

**GoDaddy:**
1. Go to: My Products → Domains → Domain Settings
2. Click "Manage DNS"
3. Click "Change Nameservers"
4. Select "Custom Nameservers"
5. Paste the Azure nameservers
6. Click "Save"

**Namecheap:**
1. Go to: Domain List → Manage
2. Find "Nameservers" section
3. Select "Custom DNS"
4. Paste the Azure nameservers
5. Click the checkmark to save

**Cloudflare:**
1. Go to: Domain Registration → Manage Domains
2. Click on your domain
3. Go to "Nameservers" tab
4. Update to use Azure nameservers

**Google Domains:**
1. Go to: My Domains → Manage
2. Click "DNS" in the left sidebar
3. Select "Use custom name servers"
4. Enter the Azure nameservers
5. Click "Save"

#### Step 3: Verify DNS Propagation

DNS propagation can take anywhere from 5 minutes to 48 hours (usually 1-2 hours).

**Check propagation status:**

```powershell
# Check if Azure is responding
nslookup -type=SOA romaine.life

# Check nameservers
nslookup -type=NS romaine.life

# Online checker (use any of these)
# https://dnschecker.org/
# https://www.whatsmydns.net/
```

**What to look for:**
- The SOA record should point to Azure DNS (e.g., `ns1-01.azure-dns.com`)
- All nameservers should be Azure nameservers
- The check should succeed globally (green checkmarks on online checkers)

⚠️ **Don't proceed to Phase 2 until DNS has propagated!**

---

### Phase 2: Deploy Custom Domain Configuration

Once DNS has propagated, deploy the custom domain configuration with Terraform.

#### Step 1: Review Terraform Plan

```powershell
cd tofu
tofu plan
```

**Expected resources:**
- `azurerm_dns_cname_record.frontend` - CNAME for workout.romaine.life
- `azurerm_dns_cname_record.backend` - CNAME for api.workout.romaine.life
- `azurerm_static_web_app_custom_domain.frontend` - Custom domain binding for frontend
- `azurerm_container_app_custom_domain.backend` - Custom domain binding for backend
- Updates to Container App (CORS + FRONTEND_URL environment variable)

#### Step 2: Apply Configuration

```powershell
tofu apply
```

Type `yes` when prompted.

**What happens:**
1. ✅ Creates CNAME records in Azure DNS
2. ✅ Binds custom domains to Static Web App and Container App
3. ✅ Azure automatically provisions SSL certificates
4. ✅ Updates Container App CORS to allow custom domain

**Timeline:**
- DNS records created: ~1 minute
- Domain verification: 2-5 minutes
- SSL certificate provisioning: 5-15 minutes
- Total: ~10-20 minutes

#### Step 3: Monitor SSL Certificate Provisioning

**Check Static Web App:**
```powershell
az staticwebapp show `
  --name workout-app-[suffix] `
  --resource-group workout-rg `
  --query "customDomains"
```

**Check Container App:**
```powershell
az containerapp hostname list `
  --name workout-api `
  --resource-group workout-rg `
  --query "[].{Domain:name,Status:bindingType}" `
  --output table
```

---

### Phase 3: Verification

#### Step 1: Test DNS Resolution

```powershell
# Test frontend domain
nslookup workout.romaine.life

# Test backend domain
nslookup api.workout.romaine.life
```

**Expected results:**
- Both should resolve to Azure IP addresses
- No errors or timeouts

#### Step 2: Test HTTPS Access

**Frontend:**
```powershell
# PowerShell
Invoke-WebRequest -Uri "https://workout.romaine.life" -UseBasicParsing

# Or just open in browser:
start https://workout.romaine.life
```

**Backend API:**
```powershell
# PowerShell
Invoke-WebRequest -Uri "https://api.workout.romaine.life/health" -UseBasicParsing

# Or use curl
curl https://api.workout.romaine.life/health
```

#### Step 3: Verify SSL Certificates

Open both URLs in a browser and check the certificate:

1. Click the padlock icon in the address bar
2. Click "Certificate"
3. Verify:
   - ✅ Issued by: Microsoft Azure TLS Issuing CA
   - ✅ Valid from/to dates are correct
   - ✅ Subject Alternative Names include your domain
   - ✅ No certificate warnings

#### Step 4: Test Application Functionality

1. Go to `https://workout.romaine.life`
2. Test the app:
   - ✅ Page loads correctly
   - ✅ Can navigate between tabs
   - ✅ Can log workouts (tests backend API connection)
   - ✅ No CORS errors in browser console (F12 → Console)

---

## 🔧 Troubleshooting

### Issue: DNS not propagating

**Symptoms:**
- `nslookup` returns "SERVFAIL" or "Non-existent domain"
- DNS checkers show red X marks

**Solutions:**
1. Verify nameservers are correct at registrar (check for typos)
2. Wait longer - can take up to 48 hours
3. Clear your local DNS cache:
   ```powershell
   ipconfig /flushdns
   ```
4. Try a different DNS server:
   ```powershell
   nslookup romaine.life 8.8.8.8  # Google DNS
   ```

### Issue: SSL certificate not provisioning

**Symptoms:**
- Browser shows "Not Secure" or certificate warnings
- Certificate is self-signed or doesn't match domain

**Solutions:**
1. Wait longer - SSL provisioning can take up to 15 minutes
2. Check domain verification status:
   ```powershell
   az staticwebapp show `
     --name workout-app-[suffix] `
     --resource-group workout-rg `
     --query "customDomains"
   ```
3. Verify CNAME records are correct:
   ```powershell
   nslookup -type=CNAME workout.romaine.life
   nslookup -type=CNAME api.workout.romaine.life
   ```
4. Try deleting and re-adding the custom domain in Terraform

### Issue: CORS errors in browser

**Symptoms:**
- Browser console shows: "Access to fetch at 'https://api.workout.romaine.life' from origin 'https://workout.romaine.life' has been blocked by CORS policy"

**Solutions:**
1. Verify Container App CORS configuration:
   ```powershell
   az containerapp show `
     --name workout-api `
     --resource-group workout-rg `
     --query "configuration.ingress.corsPolicy"
   ```
2. Check that `https://workout.romaine.life` is in the `allowedOrigins` list
3. Re-run `tofu apply` to update CORS settings
4. Wait 1-2 minutes for changes to propagate
5. Hard refresh the frontend (Ctrl+Shift+R)

### Issue: "Custom domain already exists" error

**Symptoms:**
- Terraform apply fails with "A custom domain with this name already exists"

**Solutions:**
1. Remove existing custom domain manually:
   ```powershell
   # For Static Web App
   az staticwebapp hostname delete `
     --name workout-app-[suffix] `
     --resource-group workout-rg `
     --hostname workout.romaine.life
   
   # For Container App
   az containerapp hostname delete `
     --name workout-api `
     --resource-group workout-rg `
     --hostname api.workout.romaine.life
   ```
2. Re-run `tofu apply`

### Issue: Backend API returns 404 or 502

**Symptoms:**
- `https://api.workout.romaine.life` returns error
- Frontend shows "Network Error" when trying to save workouts

**Solutions:**
1. Check Container App is running:
   ```powershell
   az containerapp show `
     --name workout-api `
     --resource-group workout-rg `
     --query "properties.{Status:provisioningState,Running:runningStatus}"
   ```
2. Check Container App logs:
   ```powershell
   az containerapp logs show `
     --name workout-api `
     --resource-group workout-rg `
     --follow
   ```
3. Verify custom domain is bound:
   ```powershell
   az containerapp hostname list `
     --name workout-api `
     --resource-group workout-rg
   ```

---

## 🔄 Rollback / Removal

### Remove Custom Domains (Keep DNS Zone)

```powershell
cd tofu

# Comment out or delete the custom domain resources in dns.tf
# Then run:
tofu apply
```

### Delete DNS Zone Completely

```powershell
# Delete DNS zone
az network dns zone delete `
  --resource-group workout-rg `
  --name romaine.life `
  --yes

# Update registrar nameservers back to original values
```

---

## 📚 Additional Resources

**Azure Documentation:**
- [Azure DNS Overview](https://learn.microsoft.com/en-us/azure/dns/dns-overview)
- [Static Web Apps Custom Domains](https://learn.microsoft.com/en-us/azure/static-web-apps/custom-domain)
- [Container Apps Custom Domains](https://learn.microsoft.com/en-us/azure/container-apps/custom-domains-managed-certificates)

**DNS Tools:**
- [DNS Checker](https://dnschecker.org/) - Check global DNS propagation
- [What's My DNS](https://www.whatsmydns.net/) - Another propagation checker
- [MXToolbox](https://mxtoolbox.com/SuperTool.aspx) - Comprehensive DNS diagnostics

**Troubleshooting:**
- [Azure DNS Troubleshooting](https://learn.microsoft.com/en-us/azure/dns/dns-troubleshoot)
- [Static Web Apps Custom Domain Issues](https://learn.microsoft.com/en-us/azure/static-web-apps/custom-domain-troubleshoot)

---

## 📞 Quick Reference Commands

```powershell
# Bootstrap DNS zone
cd tofu
.\bootstrap-dns.ps1

# Check DNS propagation
nslookup -type=NS romaine.life

# Deploy custom domains
tofu plan
tofu apply

# Test domains
curl https://workout.romaine.life
curl https://api.workout.romaine.life/health

# View Container App logs
az containerapp logs show --name workout-api --resource-group workout-rg --follow

# Check SSL certificate status
az staticwebapp show --name workout-app-[suffix] --resource-group workout-rg --query customDomains
az containerapp hostname list --name workout-api --resource-group workout-rg

# Flush local DNS cache
ipconfig /flushdns
```

---

**Questions or Issues?**
- Check the troubleshooting section above
- Review Terraform output for error messages
- Check Azure Portal for resource status
- View Container App logs for backend issues
