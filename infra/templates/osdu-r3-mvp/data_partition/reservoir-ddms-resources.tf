//  Copyright © Microsoft Corporation
//  Copyright © EPAM Systems
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
  reservoir_postgresql_name = "${local.base_name}-res-pg"
  reservoir_database_names = [
    "postkv"
  ]
  reservoir_postgres_username = "postgres"
  reservoir_postgres_password = random_password.postgres_reservoir[0].result

  reservoir_postgres_conn_identifier = format("%s-reservoir-conn", var.data_partition_name)

  reservoir_role = "Contributor"
  reservoir_rbac_principals = [
    // OSDU Identity
    data.terraform_remote_state.central_resources.outputs.osdu_identity_principal_id,

    // Service Principal
    data.terraform_remote_state.central_resources.outputs.principal_objectId
  ]
}

resource "random_password" "postgres_reservoir" {
  count            = var.reservoir_ddms.enabled ? 1 : 0
  length           = 8
  special          = true
  override_special = "_%@"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

module "postgresql_reservoir" {
  count  = var.reservoir_ddms.enabled ? 1 : 0
  source = "../../../modules/providers/azure/postgreSQL"

  resource_group_name       = azurerm_resource_group.main.name
  name                      = local.reservoir_postgresql_name
  databases                 = local.reservoir_database_names
  admin_user                = local.reservoir_postgres_username
  admin_password            = local.reservoir_postgres_password
  sku                       = var.reservoir_ddms.sku
  postgresql_configurations = {}

  storage_mb                   = 5120
  server_version               = "10.0"
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = false
  ssl_enforcement_enabled      = true

  public_network_access = true
  firewall_rules = [{
    start_ip = "0.0.0.0"
    end_ip   = "0.0.0.0"
  }]

  resource_tags = var.resource_tags
}

resource "azurerm_role_assignment" "postgres_reservoir_access" {
  count = var.reservoir_ddms.enabled ? length(local.rbac_principals) : 0

  role_definition_name = local.reservoir_role
  principal_id         = local.reservoir_rbac_principals[count.index]
  scope                = module.postgresql_reservoir[0].server_id
}

resource "azurerm_key_vault_secret" "postgres_reservoir_connection" {
  count = var.reservoir_ddms.enabled ? 1 : 0
  name  = local.reservoir_postgres_conn_identifier
  value = format("host=%s port=5432 dbname=%s user=%s@%s password=%s sslmode=require",
    module.postgresql_reservoir[0].server_fqdn,
    local.reservoir_database_names[0],
    local.reservoir_postgres_username,
    local.reservoir_postgresql_name,
    local.reservoir_postgres_password
  )
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}
