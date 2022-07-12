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
  secret_svc_kv_name       = format("%s-sk", local.base_name_21)
  secret_svc_kv_identifier = "secret-service-keyvault-uri"
}

#-------------------------------
# Key Vault
#-------------------------------
module "kv_secret_service" {
  count  = var.secret_kv_enabled ? 1 : 0
  source = "../../../modules/providers/azure/keyvault"

  keyvault_name       = local.secret_svc_kv_name
  resource_group_name = azurerm_resource_group.main.name
  secrets = {
    secret-kv-rg = local.resource_group_name
  }

  resource_tags = var.resource_tags
}

module "keyvault_policy" {
  count  = var.secret_kv_enabled ? 1 : 0
  source = "../../../modules/providers/azure/keyvault-policy"

  vault_id                = module.kv_secret_service[0].keyvault_id
  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_ids              = local.rbac_principals
  key_permissions         = ["get", "encrypt", "decrypt"]
  certificate_permissions = ["get", "update", "import"]
  secret_permissions      = ["get", "set", "delete", "recover", "list", "restore", "purge", "backup"]
}

resource "azurerm_role_assignment" "kv_secret_roles" {
  count = var.secret_kv_enabled ? length(local.rbac_principals) : 0

  role_definition_name = "Reader"
  principal_id         = local.rbac_principals[count.index]
  scope                = module.kv_secret_service[0].keyvault_id
}

resource "azurerm_key_vault_secret" "keyvault_uri_secret_service" {
  count        = var.secret_kv_enabled ? 1 : 0
  name         = local.secret_svc_kv_identifier
  value        = module.kv_secret_service[0].keyvault_uri
  key_vault_id = data.terraform_remote_state.central_resources.outputs.keyvault_id
}


## Additional notes: 
# we need to put the keyvault-uri as secret parameter in the partition service