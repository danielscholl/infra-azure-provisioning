# AKS upgrades

## M15 (0.18) -> M16 (0.19)

### PreRequisites considerations and warns

* AKS Upgrade from __1.24.0__ to __1.25.x__ ( [check for available upgrades](https://learn.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli#check-for-available-aks-cluster-upgrades) )
* __AKS Upgrade WARN__: Kubernetes has removed objects from ApiGroups between version 1.24.0 and 1.25.x. If you have any resources calling the ApiGroups below, migrate them to new ApiGroups ahead of time to avoid impact [learn more here](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#migrate-to-non-deprecated-apis)
  * CronJob - batch/v1beta1
  * EndpointSlice - discovery.k8s.io/v1beta1
  * Event - events.k8s.io/v1beta1
  * HorizontalPodAutoscaler - autoscaling/v2beta1
  * PodDisruptionBudget - policy/v1beta1
  * PodSecurityPolicy - policy/v1beta1
  * RuntimeClass - node.k8s.io/v1beta1
* Consider azure recommendations while upgrading [AKS considerations doc](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli)
  * Setup surge on nodes ()
  * Check your subscription limits (cpu and memory for new surge nodes)
  * Upgrade speed will rely on this setting, it can take up to 40m for 5 nodes, therefore, for 40 nodes it might take up to 3hrs, if surge it is not set in the nodepools.

### Upgrade path

#### 1 - Pipelines prerequisites

* It is needed to run the pipelines after [helm-charts-azure MR 541](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/merge_requests/541) and [infra-azure-provisioning MR691](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/merge_requests/784):

#### 2 - Upgrade AKS

#### Upgrade AKS control plane and nodes

It is recommended to use azure-cli (due terraform update [timeout](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#timeouts)), however you can use terraform as well, run terraform scripts by modifying the aks [timeout](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#timeouts) accordingly.

* Trough az cli:

```shell
AKS_RG=<sr-rg>
AKS_NAME=<aks-name>
# List available upgrades (check next available aks version):
az aks get-upgrades --resource-group $AKS_RG --name $AKS_NAME --output table

# From 1.24.0 AKS version:
az aks upgrade \
    --resource-group $AKS_RG \
    --name $AKS_NAME \
    --kubernetes-version 1.25.x #replace the patch version with the latest

# output:
| Kubernetes may be unavailable during cluster upgrades.
|  Are you sure you want to perform this operation? (y/N): y
| Since control-plane-only argument is not specified, this will upgrade the control plane AND all nodepools to version 1.2x.x. Continue? (y/N): y
```

You can list available versions with `az aks get-upgrades --resource-group <sr-rg> --name <sr-prefix>-aks --output table`.

### Common known issues on AKS Upgrade

Common issues that might be faced while doing upgrade.

#### Helm

* __WARN__: Some API versions has been deprecated in 1.24.4 AKS version. Please make sure to upgrade them before doing the upgrade. Follow [deprecation-guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/#v1-25) for more details

#### PDB

* __WARN__: AKS upgrade may fail because of the [Pod Disruption Budgets](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/#pod-disruption-budgets) set up in AKS for various components. Please make sure that __ALLOWED DISRUPTIONS__ for every PDB in cluster is great than or equals to 1. For more info refer below
    * [az-aks-upgrade-to-kubernetes-version](https://learn.microsoft.com/en-us/answers/questions/337433/az-aks-upgrade-to-kubernetes-version-1-18-14-is-fa)
    * [Kubernetes in production — Pod Disruption Budget](https://www.revolgy.com/insights/blog/kubernetes-in-production-poddisruptionbudget)
