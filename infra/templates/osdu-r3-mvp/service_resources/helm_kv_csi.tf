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


#-------------------------------
# KeyVault Secret Driver
#-------------------------------
locals {
  helm_kv_csi_name    = "kvsecrets"
  helm_kv_csi_ns      = "kube-system"
  helm_kv_csi_repo    = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  helm_kv_csi_version = "1.0.1"
}

resource "helm_release" "kvsecrets" {
  name       = local.helm_kv_csi_name
  repository = local.helm_kv_csi_repo
  chart      = "csi-secrets-store-provider-azure"
  version    = local.helm_kv_csi_version
  namespace  = local.helm_kv_csi_ns

  set {
    name  = "secrets-store-csi-driver.linux.metricsAddr"
    value = ":8081"
  }

  set {
    name  = "secrets-store-csi-driver.syncSecret.enabled"
    value = "true"
  }
}
