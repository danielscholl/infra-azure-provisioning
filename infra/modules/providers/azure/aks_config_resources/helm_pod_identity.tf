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
# Pod Identity
#-------------------------------
locals {
  pod_identity_name         = "${var.aks_cluster_name}-pod-identity"
  helm_pod_identity_name    = "aad-pod-identity"
  helm_pod_identity_ns      = "kube-system"
  helm_pod_identity_repo    = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  helm_pod_identity_version = "4.1.5"
}

resource "helm_release" "aad_pod_id" {
  name       = local.helm_pod_identity_name
  repository = local.helm_pod_identity_repo
  chart      = "aad-pod-identity"
  version    = local.helm_pod_identity_version
  namespace  = local.helm_pod_identity_ns
}
