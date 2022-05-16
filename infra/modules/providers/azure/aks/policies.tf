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
# + 7 resources in UT

# Ref: https://docs.microsoft.com/en-us/azure/governance/policy/assign-policy-terraform

# Authorized IP ranges should be defined on Kubernetes
resource "azurerm_resource_policy_assignment" "authorized_ip_ranges" {
  count                = var.azure_policy_enabled ? 1 : 0
  name                 = format("%s-authorized-ip-ranges", var.name)
  display_name         = format("%s - Authorized IP ranges should be defined on Kubernetes Services", var.name)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0e246bcf-5f6f-4f87-bc6f-775d4712c7ea"
  description          = "Restrict access to the Kubernetes Service Management API by granting API access only to IP addresses in specific ranges. It is recommended to limit access to authorized IP ranges to ensure that only applications from allowed networks can access the cluster."

  resource_id = azurerm_kubernetes_cluster.main.id
  enforce     = true

  parameters = <<EOF
  {
    "Effect": { "value": "Audit"}
  }
  EOF
}

# AKS private clusters should be enabled
resource "azurerm_resource_policy_assignment" "service_private_clusters" {
  count                = var.azure_policy_enabled ? 1 : 0
  name                 = format("%s-service-private-clusters", var.name)
  display_name         = format("%s - Azure Kubernetes Service Private Clusters should be enabled", var.name)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/040732e8-d947-40b8-95d6-854c95024bf8"
  description          = "Enable the private cluster feature for your Azure Kubernetes Service cluster to ensure network traffic between your API server and your node pools remains on the private network only. This is a common requirement in many regulatory and industry compliance standards."

  resource_id = azurerm_kubernetes_cluster.main.id
  enforce     = true

  parameters = <<EOF
  {
    "Effect": { "value": "Audit"}
  }
  EOF
}

# AKS should not allow privileged containers
resource "azurerm_resource_policy_assignment" "deny_privileged_containers" {
  count                = var.azure_policy_enabled ? 1 : 0
  name                 = format("%s-not-allow-privileged", var.name)
  display_name         = format("%s - Kubernetes cluster should not allow privileged containers", var.name)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/95edb821-ddaf-4404-9732-666045e056b4"
  description          = "Do not allow privileged containers creation in a Kubernetes cluster. This recommendation is part of CIS 5.2.1 which is intended to improve the security of your Kubernetes environments. This policy is generally available for Kubernetes Service (AKS), and preview for AKS Engine and Azure Arc enabled Kubernetes. For more information, see https://aka.ms/kubepolicydoc."

  resource_id = azurerm_kubernetes_cluster.main.id
  enforce     = true

  parameters = <<EOF
  {
    "effect": { "value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]}
  }
  EOF
}

# AKS should not allow container privilege escalation
# Discussion: https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/merge_requests/278#note_117611
resource "azurerm_resource_policy_assignment" "deny_privilege_escalation" {
  count                = var.azure_policy_enabled ? 1 : 0
  name                 = format("%s-deny-privilege-escalation", var.name)
  display_name         = format("%s - Kubernetes clusters should not allow container privilege escalation", var.name)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1c6e92c9-99f0-4e55-9cf2-0c234dc48f99"
  description          = "Do not allow containers to run with privilege escalation to root in a Kubernetes cluster. This recommendation is part of CIS 5.2.5 which is intended to improve the security of your Kubernetes environments. This policy is generally available for Kubernetes Service (AKS), and preview for AKS Engine and Azure Arc enabled Kubernetes. For more information, see https://aka.ms/kubepolicydoc."

  resource_id = azurerm_kubernetes_cluster.main.id
  enforce     = true

  parameters = <<EOF
  {
    "effect": { "value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]},
    "excludedContainers": {"value": ["discovery"]}
  }
  EOF
}

# Kubernetes cluster pods should only use allowed volume types
# Allowed volume types can be "*"
# It is not allowed to use csi as volume type (Needed for keyvault secrets)
resource "azurerm_resource_policy_assignment" "allow_volume_types" {
  count                = var.azure_policy_enabled ? 1 : 0
  name                 = format("%s-allowed-volume-types", var.name)
  display_name         = format("%s - Kubernetes cluster pods should only use allowed volume types", var.name)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/16697877-1118-4fb1-9b65-9898ec2509ec"
  description          = "Pods can only use allowed volume types in a Kubernetes cluster. This recommendation is part of Pod Security Policies which are intended to improve the security of your Kubernetes environments. This policy is generally available for Kubernetes Service (AKS), and preview for AKS Engine and Azure Arc enabled Kubernetes. For more information, see https://aka.ms/kubepolicydoc."

  resource_id = azurerm_kubernetes_cluster.main.id
  enforce     = true

  parameters = <<EOF
  {
    "effect": { "value": "audit"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]},
    "allowedVolumeTypes": {"value": ["*"]}
  }
  EOF
}

# Kubernetes cluster pod hostPath volumes should only use allowed host path
# kvsecrets CSI controller needs this privilege and podidentity as well (moved to kube-system ns)
resource "azurerm_resource_policy_assignment" "allowed_host_paths" {
  count                = var.azure_policy_enabled ? 1 : 0
  name                 = format("%s-allowed-host-paths", var.name)
  display_name         = format("%s - Kubernetes cluster pod hostPath volumes should only use allowed host paths", var.name)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/098fc59e-46c7-4d99-9b16-64990e543d75"
  description          = "Limit pod HostPath volume mounts to the allowed host paths in a Kubernetes Cluster. This recommendation is part of Pod Security Policies which are intended to improve the security of your Kubernetes environments. This policy is generally available for Kubernetes Service (AKS), and preview for AKS Engine and Azure Arc enabled Kubernetes. For more information, see https://aka.ms/kubepolicydoc."

  resource_id = azurerm_kubernetes_cluster.main.id
  enforce     = true

  parameters = <<EOF
  {
    "effect": { "value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc", "agic"]}
  }
  EOF
}

# Kubernetes cluster pods should only use approved host network and port range
resource "azurerm_resource_policy_assignment" "allowed_host_net_port" {
  count                = var.azure_policy_enabled ? 1 : 0
  name                 = format("%s-allowed-host-net-port", var.name)
  display_name         = format("%s - Kubernetes cluster pods should only use approved host network and port range", var.name)
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/82985f06-dc18-4a48-bc1c-b9f4f0098cfe"
  description          = "Restrict pod access to the host network and the allowable host port range in a Kubernetes cluster. This recommendation is part of CIS 5.2.4 which is intended to improve the security of your Kubernetes environments. This policy is generally available for Kubernetes Service (AKS), and preview for AKS Engine and Azure Arc enabled Kubernetes. For more information, see https://aka.ms/kubepolicydoc."

  resource_id = azurerm_kubernetes_cluster.main.id
  enforce     = true

  parameters = <<EOF
  {
    "effect": { "value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]},
    "allowHostNetwork": {"value": false},
    "minPort": {"value": 0},
    "maxPort": {"value": 0}
  }
  EOF
}
