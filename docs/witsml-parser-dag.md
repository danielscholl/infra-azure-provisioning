# Instructions for Loading WITSML Parser DAG

For loading WITSML Parser DAG we would need to create two docker images

- Docker image for WITSML Parser
- Docker image for loading and registering WITSML Parser DAG

## Building and pushing Docker Image for WITSML Parser
- Execute the below script from root of [WITSML Parser project](https://community.opengroup.org/osdu/platform/data-flow/ingestion/energistics-osdu-integration)


```bash
TAG="latest"
ACR_REGISTRY="msosdu.azurecr.io"

docker build --target azure -f build/Dockerfile -t ${ACR_REGISTRY}/witsml-parser:${TAG} .
docker push ${ACR_REGISTRY}/witsml-parser:${TAG}
```

## Building and pushing Docker Image for WITSML Parser DAG

- Execute the below script from root of [WITSML Parser project](https://community.opengroup.org/osdu/platform/data-flow/ingestion/energistics-osdu-integration) to build and load the WITSML Parser DAG

```bash

# Setup Variables
TAG="0.13.0"
AZURE_DNS_NAME="<your_osdu_fqdn>"             # ie: osdu-$UNIQUE.contoso.com
ACR_REGISTRY="<your_acr_fqdn>"                # ie: msosdu.azurecr.io
KEY_VAULT_NAME="<your_keyvault_name>"
DATA_PARTITION="<your_data_partition_name>"
WITSML_PARSER_IMAGE="${ACR_REGISTRY}/witsml-parser:$TAG"
# Optional variable, it takes default value of "airflow2dags", Airflow 2.x is recommended over Airflow 1.x
# To keep on using Airflow 1.x use "airflowdags"
K8S_NAMESPACE="<airflow_namespace>"               # Optional defaults to airflow2, use airflow for Airflow 1.x
FILE_SHARE="<airflow_file_share_name>"            # Optional defaults airflow2dags

# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

cat > .env << EOF
AZURE_TENANT_ID=$ARM_TENANT_ID
AZURE_CLIENT_ID=$(az keyvault secret show --id https://${KEY_VAULT_NAME}.vault.azure.net/secrets/app-dev-sp-username --query value -otsv)
AZURE_CLIENT_SECRET=$(az keyvault secret show --id https://${KEY_VAULT_NAME}.vault.azure.net/secrets/app-dev-sp-password --query value -otsv)
KEY_VAULT_NAME=$KEY_VAULT_NAME
AZURE_DNS_NAME=$AZURE_DNS_NAME
DATA_PARTITION=$DATA_PARTITION
WITSML_IMAGE_NAME=$WITSML_PARSER_IMAGE
EOF

WITSML_DAG_IMAGE="$ACR_REGISTRY/witsml-parser-dag:$TAG"

docker build -f deployments/scripts/azure/dag_bootstrap/Dockerfile -t $WITSML_DAG_IMAGE .
docker push $WITSML_DAG_IMAGE
docker run -it --env-file .env $WITSML_DAG_IMAGE
```
