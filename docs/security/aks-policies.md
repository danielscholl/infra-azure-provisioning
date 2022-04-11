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

In terraform state [service_resources/main.tf](../../infra/templates/osdu-r3-mvp/service_resources/main.tf), you can enable or disable policy installation in aks module:

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

```
# kubectl apply -f not-allowed.yaml 
Error from server ([azurepolicy-psp-container-no-privilege-esc-e6a74aee95507167737f] Privilege escalation container is not allowed: nginx): error when creating "not-allowed.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [azurepolicy-psp-container-no-privilege-esc-e6a74aee95507167737f] Privilege escalation container is not allowed: nginx
```

__NOTE__: Since network policy was applied, you might notice that external traffic is now prohibited.

__TODO__: Remove istio-system and airflow2 namespaces and fix the helm charts values to comply with the __deny_privilege_escalation__ policy __"Kubernetes clusters should not allow container privilege escalation"__, as for now those namespaces are not compliant, therefore the policy is configured to exclude those.