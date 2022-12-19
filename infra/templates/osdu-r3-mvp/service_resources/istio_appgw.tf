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

module "istio_appgateway" {
  source = "../../../modules/providers/azure/appgw_istio"

  name                = local.istio_app_gw_name
  resource_group_name = azurerm_resource_group.main.name

  vnet_name                       = module.network.name
  vnet_subnet_id                  = module.network.subnets.0
  keyvault_id                     = data.terraform_remote_state.central_resources.outputs.keyvault_id
  keyvault_secret_id              = azurerm_key_vault_certificate.istio_ssl_certificate.versionless_secret_id
  ssl_certificate_name            = local.istio_ssl_cert_name
  ssl_policy_type                 = var.ssl_policy_type
  ssl_policy_cipher_suites        = var.ssl_policy_cipher_suites
  ssl_policy_min_protocol_version = var.ssl_policy_min_protocol_version
  backend_address_pool_ips        = local.istio_int_load_balancer_ip == "" ? null : [local.istio_int_load_balancer_ip]

  gateway_zones = local.gateway_zones

  resource_tags   = var.resource_tags
  min_capacity    = var.istio_appgw_min_capacity
  max_capacity    = var.istio_appgw_max_capacity
  host_name       = var.aks_dns_host
  request_timeout = 300
}

// Give AD Principal Access rights to Change the Istio Application Gateway 
resource "azurerm_role_assignment" "istio_appgw_contributor" {
  principal_id         = data.terraform_remote_state.central_resources.outputs.osdu_identity_principal_id
  scope                = module.istio_appgateway.id
  role_definition_name = "Contributor"

  depends_on = [module.istio_appgateway]
}

// Give AD Principal the rights to look at the Resource Group
resource "azurerm_role_assignment" "istio_appgw_resourcegroup_reader" {
  principal_id         = data.terraform_remote_state.central_resources.outputs.osdu_identity_principal_id
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"

  depends_on = [module.istio_appgateway]
}

// Give AD Principal Access rights to Operate the Istio Application Gateway Identity
resource "azurerm_role_assignment" "istio_appgw_contributor_for_adsp" {
  principal_id         = data.terraform_remote_state.central_resources.outputs.osdu_identity_principal_id
  scope                = module.istio_appgateway.managed_identity_resource_id
  role_definition_name = "Managed Identity Operator"

  depends_on = [module.istio_appgateway]
}
