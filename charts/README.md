# Helm Installation Instructions

1. Download [helm-config.yaml](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/raw/master/charts/helm-config.yaml), which will configure OSDU on Azure.

```bash
wget https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/raw/master/charts/helm-config.yaml -O config.yaml
```

2. Edit the newly downloaded [config.yaml](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/raw/master/charts/helm-config.yaml) and fill out the required sections `azure`, `ingress` and `istio`.

3. Manually extract the manifests from the helm charts to your Flux Repo Directory.

```bash
SRC_DIR="<ROOT_PATH_TO_SOURCE>"      #  $HOME/source/osdu
FLUX_SRC="<FULL_PATH_TO_SOURCE>"     #  $SRC_DIR/gitops-manifests
INFRA_SRC="<FULL_PATH_TO_SOURCE>"    #  $SRC_DIR/infra-azure-provisioning
SERVICES_DIR="<FULL_PATH_TO_SOURCE>" #  $SRC_DIR/osdu-gitlab
BRANCH="master"
TAG="latest"

# Extract manifests from the common osdu chart.
helm template osdu-flux ${INFRA_SRC}/charts/osdu-common -f ${INFRA_SRC}/charts/config.yaml > ${FLUX_SRC}/providers/azure/hld-registry/osdu-common.yaml

# Extract manifests from the istio osdu chart.
helm template osdu-flux ${INFRA_SRC}/charts/osdu-istio -f ${INFRA_SRC}/charts/config.yaml > ${FLUX_SRC}/providers/azure/hld-registry/osdu-istio.yaml

# Extract manifests from the istio osdu chart.
helm template osdu-flux ${INFRA_SRC}/charts/osdu-istio-auth -f ${INFRA_SRC}/charts/config.yaml > ${FLUX_SRC}/providers/azure/hld-registry/osdu-istio-auth.yaml

# Extract manifests from each service chart.
for SERVICE in partition entitlements-azure legal storage indexer-queue indexer-service search-service delivery;
do
  helm template $SERVICE ${SERVICES_DIR}/$SERVICE/devops/azure/chart --set image.branch=$BRANCH --set image.tag=$TAG > ${FLUX_SRC}/providers/azure/hld-registry/$SERVICE.yaml
done
```
