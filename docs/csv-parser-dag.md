# Instructions for Loading CSV Parser DAG

For loading CSV Parser DAG we would need to create two docker images

- Docker image for CSV Parser
- Docker image for loading and registering CSV Parser DAG

## Building and pushing Docker Image for CSV Parser
- Execute the below script from root of CSV Parser project


```bash
TAG="latest"
ACR_REGISTRY="msosdu.azurecr.io"
mvn clean install -pl provider/csv-parser-azure -am
cd provider/csv-parser-azure
docker build -t ${ACR_REGISTRY}/csv-parser:${TAG} . 
docker push ${ACR_REGISTRY}/csv-parser:${TAG}
```

## Building and pushing Docker Image for CSV Parser DAG

- Execute the below script from root of CSV Parser project to build and load the CSV Parser  DAG

```bash
# Setup Variables
KEY_VAULT_NAME="<your_keyvault_name>"
AZURE_DNS_NAME="<your_osdu_fqdn>"             # ie: osdu-$UNIQUE.contoso.com
ACR_REGISTRY="<your_acr_fqdn>"                # ie: msosdu.azurecr.io
FILE_SHARE="<airflow_file_share_name>"         
# Optional variable, it takes default value of "airflow2dags", Airflow 2.x is recommended over Airflow 1.x
# To keep on using Airflow 1.x use "airflowdags"
NAMESPACE="<airflow_namespace>"               # Optional defaults to airflow2, use airflow for Airflow 1.x
CSV_DAG_IMAGE="$ACR_REGISTRY/csv-parser-dag"
TAG="0.13.0"

# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

cat > .env << EOF
TAG=$TAG
KEY_VAULT_NAME=$KEY_VAULT_NAME
AZURE_TENANT_ID=$ARM_TENANT_ID
AZURE_DNS_NAME=$AZURE_DNS_NAME
AZURE_CLIENT_ID=$(az keyvault secret show --id https://${KEY_VAULT_NAME}.vault.azure.net/secrets/app-dev-sp-username --query value -otsv)
AZURE_CLIENT_SECRET=$(az keyvault secret show --id https://${KEY_VAULT_NAME}.vault.azure.net/secrets/app-dev-sp-password --query value -otsv)
EOF

docker build -f deployments/scripts/azure/dag_bootstrap/Dockerfile -t $CSV_DAG_IMAGE:$TAG .
docker push $CSV_DAG_IMAGE:$TAG
docker run -it --env-file .env $CSV_DAG_IMAGE:$TAG
```