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

# ============================================================================
# Email DNS Records (Google Workspace)
# ============================================================================

# MX Records - Email delivery via Google Workspace
resource "azurerm_dns_mx_record" "email" {
  name                = "@" # Root domain
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    preference = 1
    exchange   = "aspmx.l.google.com"
  }

  record {
    preference = 5
    exchange   = "alt1.aspmx.l.google.com"
  }

  record {
    preference = 5
    exchange   = "alt2.aspmx.l.google.com"
  }

  record {
    preference = 10
    exchange   = "alt3.aspmx.l.google.com"
  }

  record {
    preference = 10
    exchange   = "alt4.aspmx.l.google.com"
  }

}

# Root domain TXT records (SPF, Google site verification, landing page SWA validation)
resource "azurerm_dns_txt_record" "apex" {
  name                = "@" # Root domain
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    value = "v=spf1 include:_spf.google.com ~all"
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
    value = "v=DMARC1; p=quarantine; rua=mailto:nelson@romaine.life"
  }

}

# DKIM Record - Google Workspace email authentication
# Generate the DKIM key in Google Admin Console:
# Apps > Google Workspace > Gmail > Authenticate email > Generate new record
# Then replace the placeholder value below with the generated key.
resource "azurerm_dns_txt_record" "dkim" {
  name                = "google._domainkey" # Google Workspace selector
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600

  record {
    value = "v=DKIM1; k=rsa; p=PLACEHOLDER_GENERATE_IN_GOOGLE_ADMIN"
  }

}


# Auth0 Custom Domain
resource "azurerm_dns_cname_record" "auth0" {
  name                = "auth"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 3600
  record              = auth0_custom_domain.main.verification[0].methods[0].record

}

