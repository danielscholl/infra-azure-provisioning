# AKS pod policies

Reference links:

* [AKS engine policy reference](https://docs.microsoft.com/en-us/azure/aks/policy-reference#aks-engine)
* [AKS initiatives](https://docs.microsoft.com/en-us/azure/aks/policy-reference#initiatives)
* [Understand AKS policies](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes)
* [Validate Policy](https://docs.microsoft.com/en-us/azure/aks/use-azure-policy#validate-a-azure-policy-is-running)

Applied changes:

* Refactored AKS module added policies.tf
* Optional installation of policies
* Refactored variables, removed dashboard
* Terraform azurerm provider needed __2.98.0__
  * If you're planning to upgrade provider, use `-upgrade` while doing `terraform init`.

## Optional policy installation

In __service resources__ terraform stage and __Airflow data partition__ you can enable or disable policy installation in aks module:

* [service_resources/main.tf](../../infra/templates/osdu-r3-mvp/service_resources/main.tf):
* [data_partition/airflow/airflow_main.tf](../../infra/templates/osdu-r3-mvp/data_partition/airflow/airflow_main.tf)

```terraform
module "aks" {
  source = "../../../modules/providers/azure/aks"

  name                = local.aks_cluster_name
  # ... More parameters ... #
  # Optional policy enablement
  azure_policy_enabled      = true   

  resource_tags = var.resource_tags
}
```

### Policies introduced as for now (2022-04)

* Authorized IP ranges should be defined on Kubernetes (audit)
* AKS private clusters should be enabled (audit)
* AKS should not allow privileged containers (deny)
* AKS should not allow container privilege escalation (deny)
* Kubernetes cluster pods should only use allowed volume types (deny)
* Kubernetes cluster pod hostPath volumes should only use allowed host path (deny)
* Kubernetes cluster pods should only use approved host network and port range (deny)

### Downtime and what to expect

__NOTE__: If policy is applied when a workload (pod) is runnigt and does not meet policy condition, downtime will not happen, Azure will mark that pod as non-compliant, however, if the pod gets recreated, the pod will not start due policy violation.

Screenshots and AKS non-compliant policy:

![image](../images/security/aks-policy.png)

Test for not allowed privileged pod:

```yaml
kind: Pod
metadata: 
  name: nginx-privilege-escalation-allowed
  labels: 
    app: nginx-privilege-escalation
spec: 
  containers: 
  - name: nginx
    image: nginx
    securityContext: 
      allowPrivilegeEscalation: true
```

```shell
kubectl apply -f not-allowed.yaml 

Error from server ([azurepolicy-psp-container-no-privilege-esc-e6a74aee95507167737f] Privilege escalation container is not allowed: nginx): error when creating "not-allowed.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [azurepolicy-psp-container-no-privilege-esc-e6a74aee95507167737f] Privilege escalation container is not allowed: nginx
```

## How to fix policies (2022/05)

Most of the policies introduced are already compliant, by using recommended parameters for `flux`, `kvsecrets`, `podidentity`, those policies are being checked with gatewaykeeper built-in AKS plugin.

Nevertheless, we have 1 remaining policy (Disable public AKS controlplane) which will be checked at Azure resource level, however you may need to find another approach to install and connect to your AKS cluster [Options to connect](https://docs.microsoft.com/en-us/azure/aks/private-clusters#options-for-connecting-to-the-private-cluster).

* AKS private clusters should be enabled (audit)
  1. [Disable AKS Public FQDN](https://docs.microsoft.com/en-us/azure/aks/private-clusters#disable-public-fqdn)
      * This can be enabled adding option `private_cluster_enabled=true` either on __service resources__ or in __Airflow DataPartition__, however __THIS OPTION REQUIRES RESOURCE REPLACE__, check this [aks terraform link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#private_cluster_enabled) for more info
          * [service_resources/main.tf](../../infra/templates/osdu-r3-mvp/service_resources/main.tf):
          * [data_partition/airflow/airflow_main.tf](../../infra/templates/osdu-r3-mvp/data_partition/airflow/airflow_main.tf)
  2. [Configure Private DNS ZONE](https://docs.microsoft.com/en-us/azure/aks/private-clusters#configure-private-dns-zone)
  * [Options to connect](https://docs.microsoft.com/en-us/azure/aks/private-clusters#options-for-connecting-to-the-private-cluster)
  * __WARN__: This is an experimental feature, not yet fully supported, you need to plan accordingly to enable this feature, if you're installing terraform code outside of AKS internal network, you'll end up with broken helm chart installation, unfortunately, there will not be recovery until you get access to the internal AKS endpoint either with solution for connection options described above.
* __Fixed__ Authorized IP ranges should be defined on Kubernetes (audit)
  * Use the parameter `aks_authorized_ip_ranges` in the [terraform.tfvars](../../infra/templates/osdu-r3-mvp/service_resources/terraform.tfvars) on `service resources` stage, I.E:
  * Also you can change this manually in Azure console in `AKS > Networking > Security > Set authorized IP ranges`
  * By default this parameter is set to `0.0.0.0/0` (allow all)

Example in [terraform.tfvars](../../infra/templates/osdu-r3-mvp/service_resources/terraform.tfvars) on `service resources` (EOF).

```terraform
aks_authorized_ip_ranges = ["192.168.0.1/24", "192.168.2.1/24" ...]
```

## Policy exceptions

* __Namespaces__
  * __Kube System__: Installation of kvsecrets, csi provider and podidentity helm charts will be done here.
  * __Gatekeeper system__: Policy add-on requires privileges,therefore we need to add exception for this namespace.
  * __agic__: AGIC controller does requires hostPath:

```yaml
  - hostPath:
        path: /etc/kubernetes/
        type: Directory
```

* __Containers__
  * __discovery__: `istiod` container does not have current options to put `allowPrivilegeEscalation: false`.
  * __configure-sysctl__: Can be removed if Elastic is not installed in current AKS, just needed in case EKS cluster will be installed in AKS.
  * __istio-init__: Recently we found out that sidecar does needs privilege escalation in some automated pipeline installation scenarios, still, with manual installation it is working fine.
    * Inconsistencies [this repo](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/blob/cd9c94e68026bd56044df26ee984453d216f64aa/charts/osdu-istio/templates/istio-operator-install.yaml#L240) vs [helm-manual-install](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/blob/6f1ecd7a8bc6c49252b1923587c30959950e8bdb/osdu-istio/istio-operator/files/gen-operator.yaml#L178), need further testing to figure this issue out.

* __Kubernetes cluster pods should only use allowed volume types__: We are using kvsecrets mount, which is csi provider, this will mutate the pod definition, disallowing the creation of the osdu pods which will use the volume type, most of the OSDU services are using following volume spec:

```yaml
        - name: azure-keyvault
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: azure-keyvault
```

Unfortunately, this is no working with the current policy, therefore, we needed to use policy exeption for this policy:

```json
{
  "effect": { "value": "audit"},
  "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]},
  "allowedVolumeTypes": {"value": ["*"]}
}
```

__NOTE__: We already tried several combinations, plus configmaps, secrets, csi, keyvault, both, and none of those have worked for us, we are planning to follow up to comply with least privilege principle. [issue 227](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/issues/227)

### Adopt exemptions for each policy

If for some reason you need custom exeption in a policy, you will need to modify the policy depending on the level on which the policy is applied, if the policy is applied at AKS resource level (how it is recommended to be configured by azure providers), you need to modify the policy in the AKS module [policies.tf](../../infra/modules/providers/azure/aks/policies.tf)

Take as an example the policy "[Kubernetes should not allow privilege escalation](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F1c6e92c9-99f0-4e55-9cf2-0c234dc48f99)"

Policy looks like this:

```json
{
  "properties": {
   --- CUT OUTPUT ---
    "parameters": {
      "effect": {
        "type": "String",
        "metadata": {
          "displayName": "Effect",
          "description": "'audit' allows a non-compliant resource to be created or updated, but flags it as non-compliant. 'deny' blocks the non-compliant resource creation or update. 'disabled' turns off the policy."
        },
        "allowedValues": [
          "audit",
          "Audit",
          "deny",
          "Deny",
          "disabled",
          "Disabled"
        ],
        "defaultValue": "Audit"
      },
      "excludedNamespaces": {
        "type": "Array",
        "metadata": {
          "displayName": "Namespace exclusions",
          "description": "List of Kubernetes namespaces to exclude from policy evaluation. System namespaces \"kube-system\", \"gatekeeper-system\" and \"azure-arc\" are always excluded by design."
        },
        "defaultValue": [
          "kube-system",
          "gatekeeper-system",
          "azure-arc"
        ]
      },
      "namespaces": {
        "type": "Array",
        "metadata": {
          "displayName": "Namespace inclusions",
          "description": "List of Kubernetes namespaces to only include in policy evaluation. An empty list means the policy is applied to all resources in all namespaces."
        },
        "defaultValue": []
      },
      "labelSelector": {
        "type": "Object",
        "metadata": {
          "displayName": "Kubernetes label selector",
          "description": "Label query to select Kubernetes resources for policy evaluation. An empty label selector matches all Kubernetes resources."
        },
        "defaultValue": {},
      },
      "excludedContainers": {
        "type": "Array",
        "metadata": {
          "displayName": "Containers exclusions",
          "description": "The list of InitContainers and Containers to exclude from policy evaluation. The identify is the name of container. Use an empty list to apply this policy to all containers in all namespaces."
        },
        "defaultValue": []
      },
      "excludedImages": {
        "type": "Array",
        "metadata": {
          "displayName": "Image exclusions",
          "description": "The list of InitContainers and Containers to exclude from policy evaluation. The identifier is the image of container. Prefix-matching can be signified with `*`. For example: `myregistry.azurecr.io/istio:*`. It is recommended that users use the fully-qualified Docker image name (e.g. start with a domain name) in order to avoid unexpectedly exempting images from an untrusted repository."
        },
        "defaultValue": []
      }
    },
    === CUT OUTPUT ===
  },
  "id": "/providers/Microsoft.Authorization/policyDefinitions/1c6e92c9-99f0-4e55-9cf2-0c234dc48f99",
  "type": "Microsoft.Authorization/policyDefinitions",
  "name": "1c6e92c9-99f0-4e55-9cf2-0c234dc48f99"
}
```

As noticed about the exeption can be configured at parameter level, depending on each policy parameter, this can be reviewed in the azure console in the parameters section.

As an example, we will provide a use case for __elasticsearch__ installed in the AKS in the elasticsearch namespace, which does needs the `configure-sysctl` container to have privilege escalation enabled:

In this case if we need to exclude a namespace (I.E __elasticsearch__), we would need to modify in the [policies.tf](../../infra/modules/providers/azure/aks/policies.tf) file:

```terraform
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
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc", "elasticsearch"]},
    "excludedContainers": {"value": ["discovery"]}
  }
  EOF
}
```

However if we would like to follow the least privilege principle, we would need to configure either with `labelSelector`, `excludedImages`, `excludedContainers` in this specific case (this will depend on the policy definition), in this example we can take a look [store-policy-core.windows.net](https://store.policy.core.windows.net/kubernetes/container-no-privilege-escalation/v3/template.yaml):

```terraform
resource "azurerm_resource_policy_assignment" "deny_privilege_escalation" {
  /* 
  Reduced lines
  */
  parameters = <<EOF
  {
    "effect": { "value": "deny"},
    "excludedNamespaces": {"value": ["kube-system", "gatekeeper-system", "azure-arc"]},
    "excludedContainers": {"value": ["discovery", "configure-sysctl"]}
    "excludedImages": {"value": ["msosdu.azurecr.io/configure-sysctl*"]}
  }
  EOF
}
```

__NOTE 1__: `namespace` + `excludedContainers` will apply the policy only in the specified namespace, and exclude the containers in that namespace, leaving all namespaces with no policy enforcement.

#### Subscription level policies

We are using built-in AKS policies which are customized to work with OSDU components, nevertheless, if you have already policies in place at subscription level, you will need to ask administrator, to allow exemptions at least for the following policies:

* __deny_privilege_escalation__ policy __"Kubernetes clusters should not allow container privilege escalation"__.
  * We are excluding potential containers which may need these privileges for istio-mesh to control ip table rules and redirect traffic `"excludedContainers" : ["discovery", "istio-init"]`, unfortunately there is deep configuration to do in these containers which will broke functionality, and will not allow any container to boot up if this is not allowed, as mentioned above this can be configured in the azure console under `policy settings > parameters`.
* __allowed_host_paths__
  * `"excludedNamespaces" : ["kube-system", "gatekeeper-system", "agic"]`, additionally to the system namespaces if AGIC controller is meant to be installed, you will need to exclude that namespace as well, can be excluded by setting this in the parameters policy at subscription level.
* __Kubernetes cluster pods should only use allowed volume types__
  * Motivation: We are using kvsecrets mount, which is csi provider, however, this approach is mutating the pod definition, disallowing the creation of the osdu pods which will use the volume type, most of the OSDU services are using this approach plus airflow pods as well.
  * `"allowedVolumeTypes": {"value": ["*"]}`
