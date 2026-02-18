# ============================================================================
# Shared DNS Configuration - Email Records
# ============================================================================
# This file contains DNS records that are shared across the domain, such as
# email (MX, SPF) and autodiscover records. App-specific DNS records are
# managed by the azure-app module in each app's repository.
# ============================================================================

# ============================================================================
# Name Server Records
# ============================================================================

resource "azurerm_dns_ns_record" "main" {
  name                = "@" # Root domain
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 172800 # 48 hours - standard for NS records

  records = [
    "ns1-09.azure-dns.com.",
    "ns2-09.azure-dns.net.",
    "ns3-09.azure-dns.org.",
    "ns4-09.azure-dns.info.",
  ]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "DNS"
  }
}

# ============================================================================
# Email DNS Records (Namecheap Private Email)
# ============================================================================

# MX Records - Email delivery
resource "azurerm_dns_mx_record" "email" {
  name                = "@" # Root domain
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    preference = 10
    exchange   = "mx1.privateemail.com"
  }

  record {
    preference = 10
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
  zone_name           = data.azurerm_dns_zone.main.name
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

# Autoconfig - Email client configuration
resource "azurerm_dns_cname_record" "autoconfig" {
  name                = "autoconfig"
  zone_name           = data.azurerm_dns_zone.main.name
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
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  record              = "privateemail.com"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Purpose     = "Email"
  }
}
