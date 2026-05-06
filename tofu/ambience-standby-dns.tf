locals {
  ambience_native_standby_count        = 5
  ambience_native_standby_gateway_ipv4 = "172.179.163.96"
}

resource "azurerm_dns_a_record" "ambience_native_standby" {
  for_each = toset([
    for slot in range(1, local.ambience_native_standby_count + 1) : tostring(slot)
  ])

  name                = "ambience-slot-${each.key}.ambience.dev"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  records             = [local.ambience_native_standby_gateway_ipv4]
}
