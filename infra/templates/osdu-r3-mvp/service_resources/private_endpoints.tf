//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

locals {
  # Define resources that should be using private endpoints here
  private_zones = {
    redis = {
      dns_zone = "redis.cache.windows.net"
      resource_ids = [
        module.redis_cache.id,
        module.redis_queue.id,
      ]
      private_dns_zone_name = "privatelink-redis-cache-windows-net"
      subresource_names     = ["redisCache"]
    }
  }

  private_endpoints = flatten([
    for pz_key, pz in local.private_zones : [
      for index, rid in pz.resource_ids : {
        name                  = format("%s%s", pz_key, index)
        pe_name               = format("%s-%s-pe", pz_key, element(split("/", rid), length(split("/", rid)) - 1))
        resource_id           = rid
        subresource_names     = pz.subresource_names
        is_manual_connection  = false
        private_dns_zone_name = pz.private_dns_zone_name
        private_dns_zone_ids  = [azurerm_private_dns_zone.private[pz_key].id]
      }
    ]
  ])
}

resource "azurerm_private_dns_zone" "private" {
  for_each            = local.private_zones
  name                = each.value.dns_zone
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "service_dnslink" {
  for_each              = local.private_zones
  name                  = format("%s-%s", local.base_name, each.key)
  private_dns_zone_name = azurerm_private_dns_zone.private[each.key].name
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = module.network.id
}

resource "azurerm_private_endpoint" "service" {
  for_each            = { for pe in local.private_endpoints : pe.name => pe }
  location            = azurerm_resource_group.main.location
  name                = each.value.pe_name
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.network.subnets.1

  private_service_connection {
    is_manual_connection           = each.value.is_manual_connection
    name                           = each.value.pe_name
    private_connection_resource_id = each.value.resource_id
    subresource_names              = each.value.subresource_names
  }

  private_dns_zone_group {
    name                 = each.value.private_dns_zone_name
    private_dns_zone_ids = each.value.private_dns_zone_ids
  }
}
