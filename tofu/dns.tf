# ============================================================================
# DNS Zone
# ============================================================================
# The DNS zone is the shared domain infrastructure (romaine.life) used by
# all applications. Each app creates its own subdomains under this zone.

resource "azurerm_dns_zone" "main" {
  name                = "romaine.life"
  resource_group_name = data.azurerm_resource_group.main.name

}

# ============================================================================
# Shared DNS Configuration
# ============================================================================
# This file contains DNS records that are shared across the domain, such as
# email (MX, SPF), autodiscover, and apex domain records. Subdomain records
# are managed by each app's repository.
# ============================================================================

moved {
  from = azurerm_dns_txt_record.spf
  to   = azurerm_dns_txt_record.apex
}

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

}

# Root domain TXT records (SPF, Google site verification, landing page SWA validation)
resource "azurerm_dns_txt_record" "apex" {
  name                = "@" # Root domain
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    value = "v=spf1 include:spf.privateemail.com ~all"
  }

  record {
    value = "google-site-verification=bIQ8zuUK_DUCCoYi8zUF1CxK_Hn-1Ipah9vgn4PN2z4"
  }

  dynamic "record" {
    for_each = azurerm_static_web_app_custom_domain.landing.validation_token != "" ? [1] : []
    content {
      value = azurerm_static_web_app_custom_domain.landing.validation_token
    }
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

}

# Autoconfig - Email client configuration
resource "azurerm_dns_cname_record" "autoconfig" {
  name                = "autoconfig"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  record              = "privateemail.com"

}

# Auth0 Custom Domain
resource "azurerm_dns_cname_record" "auth0" {
  name                = "auth"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  record              = auth0_custom_domain.main.verification[0].methods[0].record

}

# Autodiscover - Email client configuration
resource "azurerm_dns_cname_record" "autodiscover" {
  name                = "autodiscover"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  record              = "privateemail.com"

}
