# ============================================================================
# DNS Zone
# ============================================================================
# The DNS zone is the shared domain infrastructure (romaine.life) used by
# all applications. Each app creates its own subdomains under this zone.

resource "azurerm_dns_zone" "main" {
  name                = "romaine.life"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "DNS"
  }
}

# ============================================================================
# Shared DNS Configuration - Email Records
# ============================================================================
# This file contains DNS records that are shared across the domain, such as
# email (MX, SPF) and autodiscover records. App-specific DNS records are
# managed by the azure-app module in each app's repository.
# ============================================================================

# ============================================================================
# Email DNS Records (Namecheap Private Email)
# ============================================================================

# MX Records - Email delivery
resource "azurerm_dns_mx_record" "email" {
  name                = "@" # Root domain
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    preference = 10
    exchange   = "mx1.privateemail.com"
  }

  record {
    preference = 20
    exchange   = "mx2.privateemail.com"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Email"
  }
}

# SPF Record - Email authentication
resource "azurerm_dns_txt_record" "spf" {
  name                = "@" # Root domain
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    value = "v=spf1 include:spf.privateemail.com ~all"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Email"
  }
}

# DMARC Record - Email authentication policy
resource "azurerm_dns_txt_record" "dmarc" {
  name                = "_dmarc"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    value = "v=DMARC1; p=none;"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Email"
  }
}

# DKIM Record - Email authentication signature
resource "azurerm_dns_txt_record" "dkim" {
  name                = "default._domainkey" # Standard Namecheap selector
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    value = "v=DKIM1;k=rsa;p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1E5ptWwKni8v4Ywx2dpXDpexypFEkNssDi9jcWfhtWYF/bhwMgKXjbhTzhcvshOoWnx5E6lV4Gyh+I0Q8dhu4wl8VgosUtWjJWUj3Zdi7jfNVh7mGuthId6jNUOqMzYi64NCMcuOuyjcIij90klgNmVQXMBHKENUVPoSXb1TZ8qRyWwz+D9l5/Yp0q0y2OnASshSj1Ik/wzE5mrGZBteWjMZLca920cZgkgorgVwZIuXjin9pzqIG4QNjgEouhWoCOgECW2CIPoqnuJ+n6LgiDFJnpPQEIOdeFbDfr4+0xrIMO3R9Uxlpu+jcYFSIbCbbqCuWt8vlA/q5qhkJ+MinQIDAQAB"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Email"
  }
}

# Autoconfig - Email client configuration
resource "azurerm_dns_cname_record" "autoconfig" {
  name                = "autoconfig"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  record              = "privateemail.com"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Email"
  }
}

# Autodiscover - Email client configuration
resource "azurerm_dns_cname_record" "autodiscover" {
  name                = "autodiscover"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  record              = "privateemail.com"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Email"
  }
}