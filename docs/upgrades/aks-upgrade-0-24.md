# AKS upgrades

## M12 (0.15) -> M13 (0.16)

### PreRequisites considerations and warns

* AKS Upgrade from __1.21.x__ to __1.24.0_ [One-minor-release-upgrade](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli#check-for-available-aks-cluster-upgrades)
* __AKS Upgrade WARN__: Minor upgrades version cannot be skipped, need to change aks version variable several times if you plan to upgrade from 1.21.x to 1.24.x, I.E 1.21.x -> 1.22.x -> 1.23.x -> 1.24.x.
* Consider azure recommendations while upgrading [AKS considerations doc](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli)
  * Setup surge on nodes ()
  * Check your subscription limits (cpu and memory for new surge nodes)
  * Upgrade speed will rely on this setting, it can take up to 40m for 5 nodes, therefore, for 40 nodes it might take up to 3hrs, if surge it is not set in the nodepools.
* Need to use latest [osdu-istio m12](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/tree/azure/m12-master/osdu-istio), as the CRD's will be deprecated, most likely you may found issue, which can be resolved by re-installing istio helm charts.
  * base-1.2.0
  * istio-operator-1.8.0
  * osdu-istio-1.1.6
* It is mandatory to upgrade first charts __(downtime would be expected)__ istio, cert-manager, agic, and keda first prior to continue with the infrastructure upgrade.
  * Istio can be upgraded through helm charts
    * __NOTE__: As for now we had not found yet approach to upgrade istio without uninstalling and re-installing, this would be a caveat to take on count.
  * cert-manager and agic either with helm commands or `terraform -target` to isolate the upgrade.
* If  you're still using KEDA1 - Upgrade manually to keda2. Follow this Documentation to do it: [Keda Upgrade](../keda-upgrade.md)
* __IMPORTANT__: KEDA 1 is deprecated on this version.

#### Pipelines prerequisites

* It is needed to run the pipelines after [helm-charts-azure MR394](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/merge_requests/394) and [infra-azure-provisioning MR691](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/merge_requests/691):
  * Run gitlab-sync pipeline
  * Run chart-osdu-common pipeline
  * Run chart-osdu-istio pipeline
    * If istio pipeline gets stuck run `kubectl delete ValidatingWebhookConfiguration istiod-istio-system`
    * Istio stuck in deleteoperator: `kubectl patch istiooperator istio-default -n istio-system -p '{"metadata":{"finalizers":[]}}' --type=merge`
  * Run chart-osdu-istio-auth pipeline
* __[WARN] This pipelines will not use flux anymore, and will use helm instead__

### Upgrade path

1. Upgrade keda to kedav2 [Instructions - Keda Upgrade](../keda-upgrade.md)
    1. __WARN__ Scale down flux deploy to 0

```shell
kubectl delete scaledobjects.keda.k8s.io --all
kubectl delete triggerauthentications.keda.k8s.io --all
NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || timeout 3 kubectl delete crd scaledobjects.keda.k8s.io --ignore-not-found=true; do
    kubectl patch crd/scaledobjects.keda.k8s.io -p '{"metadata":{"finalizers":[]}}' --type=merge
    sleep $(( NEXT_WAIT_TIME++ ))
done
[ "$NEXT_WAIT_TIME" -lt 5 ]

NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || timeout 3 kubectl delete crd triggerauthentications.keda.k8s.io --ignore-not-found=true; do
    kubectl patch crd/triggerauthentications.keda.k8s.io -p '{"metadata":{"finalizers":[]}}' --type=merge
    sleep $(( NEXT_WAIT_TIME++ ))
done
[ "$NEXT_WAIT_TIME" -lt 5 ]
```

Recommended to uninstall and re-install helm chart:

```shell
helm uninstall keda -n keda --wait --purge
helm upgrade keda keda -n keda --install --repo https://kedacore.github.io/charts \
  --version 2.7.2 --wait
```

#### 2 - Upgrade AKS-terraform helm charts

##### 2.1 - Terraform approach

Fill out the needed vars for the terraform [Instructions SR config](../../infra/templates/osdu-r3-mvp/service_resources/README.md#azure-osdu-mvc---service-resources-configuration):

```shell
# Needed terraform vars:
export ARM_TENANT_ID...
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"
TF_WORKSPACE="sr-${UNIQUE}"
terraform workspace new $TF_WORKSPACE || terraform workspace select $TF_WORKSPACE

terraform plan out /tmp/tf.plan \
  -target helm_release.agic \
  -target helm_release.certmgr \
  -target helm_release.keda \
  -target helm_release.kvsecrets \
  -target helm_release.aad_pod_id

terraform apply -auto-approve /tmp/tf.plan
```

##### 2.2 - Helm approach

Disadvantage: Lot of values to cover.

```shell
aks login <remaining parameters>

# AGIC
helm upgrade agic ingress-azure --install --repo https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/ \
  --namespace agic --version 1.5.2 \
  --set appgw.subscriptionId=<subscriptionid> \
  --set appgw.applicationGatewayID=<appgwid> \
  --set appgw.resourceGroup=<resourceGroup>
  --set appgw.name=<appgwname> \
  --set armAuth.identityResourceID=<value> \
  --set armAuth.identityClientID=<value> \
  --set armAuth.type=aadPodIdentity \
  --set appgw.shared=false \
  --set appgw.usePrivateIP=false \
  --set rbac.enabled=true \
  --set verbosityLevel=1

# Cert manager
helm upgrade jetstack cert-manager --install --repo https://charts.jetstack.io \
  --namespace cert-manager --version v1.8.2 --wait \
  --set installCRDs=true

############
##### The next helm charts may be already upgraded

# CSI for keyvault (Check first if already upgraded)
helm upgrade kvsecrets csi-secrets-store-provider-azure -n kube-system --install --repo  https://azure.github.io/secrets-store-csi-driver-provider-azure/charts \
  --version 1.0.1 --wait \
  --set secrets-store-csi-driver.linux.metricsAddr=":8081" \
  --set secrets-store-csi-driver.syncSecret.enabled=true
```

#### Upgrade AKS control plane and nodes

It is recommended to use azure-cli (due terraform update [timeout](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#timeouts)), however you can use terraform as well, run terraform scripts at the end to refresh remote state, and modify the aks [timeout](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#timeouts) accordingly.

* Trough az cli:

```shell
AKS_RG=<sr-rg>
AKS_NAME=<aks-name>
# List available upgrades (check next available aks version):
az aks get-upgrades --resource-group $AKS_RG --name $AKS_NAME --output table
# From 1.21.7 AKS version:
az aks upgrade \
    --resource-group $AKS_RG \
    --name $AKS_NAME \
    --kubernetes-version 1.22.11

# From 1.21.x AKS version:
az aks upgrade \
    --resource-group $AKS_RG \
    --name $AKS_NAME \
    --kubernetes-version 1.22.11

az aks upgrade \
    --resource-group $AKS_RG \
    --name $AKS_NAME \
    --kubernetes-version 1.23.8

# At this point terraform can be used to upgrade to 1.24.0

# output:
| Kubernetes may be unavailable during cluster upgrades.
|  Are you sure you want to perform this operation? (y/N): y
| Since control-plane-only argument is not specified, this will upgrade the control plane AND all nodepools to version 1.2x.x. Continue? (y/N): y
```

* Trough terraform:

| from 1.21.7 -> `kubernetes_version = "1.22.11"` -> `kubernetes_version = "1.23.8"` -> `kubernetes_version = "1.24.0"`

For dp airflow resources:

| from 1.21.7 -> `kubernetes_version = "1.22.11"` -> `kubernetes_version = "1.23.8"` -> `kubernetes_version = "1.24.0"`

You can list available versions with `az aks get-upgrades --resource-group <sr-rg> --name <sr-prefix>-aks --output table`.

### Common known issues on AKS Upgrade

Common issues that might be faced while doing upgrade.

#### Helm and Custom Resource Definitions (CRD)

* __WARN__: Some helm charts have crd's (istio, keda, agic), therefore, those needs to be upgraded first prior to apply this upgrade.
* __WARN__: If helm upgrade (`--wait` flag enabled) does not succeed correctly, __rely on uninstall and install__ the helm chart to avoid any inconsistency.
* __WARN__: We had see that if AKS upgrade happens prior to helm chart upgrades, this will remove old CRD's (`apiextensions.k8s.io/v1beta1`) without any warning about it, this will lead to issues in the old versions of istio operator, agic, etc, which are relying on deprecated api version, therefore, you might need to uninstall and install those helm with updated versions after AKS upgrade succeeded.

#### PBD caveats

* __PDB (PodDisruptionBudget) settings__ - Be aware the PDB may stop some pods to be deleted when draining it is happening on some nodes, if replicas for any deploy is same as PDB or lower than PBD defined, it will not allow to drain correctly the node, there are 2 approaches to use in this case
  1. __[Recommended]__ Check the PDB settings first to avoid draining to be stopped during upgrade, escale accordingly the deployments to avoid hitting lower treshold for the PBD configured.
  2. If for some reason you missed this, the AKS may stick in upgrade broken loop, in that case AKS will still try to upgrade, in this scenario, check for the nodes that are marked as `Unscheduled` for more than 5 minutes and check which pod is not allowing to drain the node, kill the pod manually with `kubectl delete pod -n <ns> <pod-name>`, then check that Node it is being replaced, this might happen with either osdu services or with istio services (those have configured PDB).

#### Istio caveats

* When CRD changes even if the charts seem to be upgraded (happened in case of Istio).
  * Istio helm chart will install CRD's based on the kubernetes version (condition in helm).
  * The suggestions:
    * Uninstall and reinstall Istio along with CRD's [Istio docs to purge](https://istio.io/latest/docs/setup/install/helm/#optional-deleting-crds-installed-by-istio).
    * Reinstall and figure out and test a way such that CRD won't block the actual upgrade of chart.
  * Also noted that sometimes the istio upgrade goes well, however, sidecar will be failing due missing CRD, in this case suggest to purge istio and reinstall, base operator and osdu-istio.
