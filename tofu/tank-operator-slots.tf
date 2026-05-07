# ============================================================================
# tank-operator slot DNS — wildcard A record per slot
# ============================================================================
# tank-operator stamps a per-session HTTPRoute with hostname
# <session-id>.tank-slot-N.tank.dev.romaine.life. The wildcard A record
# below resolves every such name (plus the slot's parent name) to the
# shared envoy-gateway IP, so per-session records don't have to be
# minted by external-dns on each session-create.
#
# Pair with: a wildcard cert for *.tank-slot-N.tank.dev.romaine.life
# (provisioned per slot in the tank-operator chart) and a wildcard
# Gateway listener (also per slot). The wildcard cert covers TLS for
# every name; the listener terminates TLS; this record points the
# names at the listener.
#
# Hardcoded gateway IP for now — the envoy-gateway LoadBalancer
# allocates a static Azure IP that's only swapped on full cluster
# rebuild. Lifting it to a data source / output would make this
# self-healing across rebuilds, but adds dependency on the k8s
# resource being applied first; deferred.
locals {
  tank_operator_slots = ["1", "2", "3"]
  envoy_gateway_ip    = "172.179.163.96"
}

resource "azurerm_dns_a_record" "tank_operator_slot_wildcard" {
  for_each = toset(local.tank_operator_slots)

  name                = "*.tank-slot-${each.value}.tank.dev"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.main.name
  ttl                 = 300
  records             = [local.envoy_gateway_ip]
}
