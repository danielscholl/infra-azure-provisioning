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

resource "local_sensitive_file" "cluster_credentials" {
  count    = var.kubeconfig_to_disk ? 1 : 0
  content  = azurerm_kubernetes_cluster.main.kube_config_raw
  filename = "${var.output_directory}/${var.kubeconfig_filename}"

  depends_on = [azurerm_kubernetes_cluster.main]
}