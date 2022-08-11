#!/bin/bash


# Cleanup function
cleanup() {
  echo "Terminating istio sidecar"
  curl -X POST "http://localhost:15020/quitquitquit"
  exit
}

trap cleanup EXIT

currentStatus=""
currentMessage=""

git clone https://community.opengroup.org/osdu/platform/system/reference/crs-conversion-service.git
if [[ $? -gt 0 ]]; then
  currentMessage="failure"
  currentMessage="${currentMessage}. Failed to clone crs-conversion-service"
fi
git clone https://community.opengroup.org/osdu/platform/system/reference/crs-catalog-service.git
if [[ $? -gt 0 ]]; then
  currentMessage="failure"
  currentMessage="${currentMessage}. Failed to clone crs-catalog-service"
fi
git clone https://community.opengroup.org/osdu/platform/system/reference/unit-service.git
if [[ $? -gt 0 ]]; then
  currentMessage="failure"
  currentMessage="${currentMessage}. Failed to clone unit-service"
fi

CRS_CONVERSION_SOURCE_FOLDER='crs-conversion-service/apachesis_setup/.'
CRS_CATALOG_SOURCE_FOLDER='crs-catalog-service/data/crs_catalog_v2.json'
UNIT_SOURCE_FOLDER='unit-service/data/unit_catalog_v2.json'

max_retry_count=7
current_retry_count=0
loginStatus=1
while [ ${current_retry_count} -lt ${max_retry_count} ];
do
    az login --identity --username $OSDU_IDENTITY_ID
    if [ $? -eq 0 ]; then
      if [ ! -z "$SUBSCRIPTION" -a "$SUBSCRIPTION" != " " ]; then
        az account set --subscription $SUBSCRIPTION
      fi

      loginStatus=0
      break
    fi
  current_retry_count=$(expr $current_retry_count + 1)
done
if [[ ${loginStatus} -ne 0 ]]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. az login exited with a failed status."
fi

ENV_VAULT=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query [].name -otsv)
STORAGE_ACCOUNT_NAME=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/system-storage --query value -otsv)
if [ -z "$STORAGE_ACCOUNT_NAME" -a "$STORAGE_ACCOUNT_NAME" == " " ]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. Storage Account Name Not Found. "
fi

echo "Fetch Connection String to connect to File Share"
STORAGE_ACCOUNT_CONNECTION_STRING=$(az storage account show-connection-string --name ${STORAGE_ACCOUNT_NAME} --query connectionString -otsv)

cd crs-conversion-service
mkdir tmp 
mv apachesis_setup tmp 
cd tmp
az storage file upload-batch --connection-string $STORAGE_ACCOUNT_CONNECTION_STRING --destination crs-conversion --source .
if [[ $? -gt 0 ]]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. Failed to copy data to crs-conversion file share"
fi
cd ../..

az storage file upload --connection-string $STORAGE_ACCOUNT_CONNECTION_STRING --share-name crs --source $CRS_CATALOG_SOURCE_FOLDER
if [[ $? -gt 0 ]]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. Failed to copy data to crs file share"
fi

az storage file upload --connection-string $STORAGE_ACCOUNT_CONNECTION_STRING --share-name unit --source $UNIT_SOURCE_FOLDER
if [[ $? -gt 0 ]]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. Failed to copy data to unit file share"
fi

if [ -z "$currentStatus" -a "$currentStatus"==" " ]; then
  currentStatus="success"
fi

echo "Current Status: ${currentStatus}"
echo "Current Message: ${currentMessage}"

if [ ! -z "$CONFIG_MAP_NAME" -a "$CONFIG_MAP_NAME" != " " ]; then
  ENV_AKS=$(az aks list --resource-group $RESOURCE_GROUP_NAME --query [].name -otsv)
  az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $ENV_AKS
  kubectl config set-context $RESOURCE_GROUP_NAME --cluster $ENV_AKS

  Status=$(kubectl get configmap $CONFIG_MAP_NAME -o jsonpath='{.data.status}')
  Message=$(kubectl get configmap $CONFIG_MAP_NAME -o jsonpath='{.data.message}')

  Message="${Message}Helper Data Seeding Message: ${currentMessage}. "

  ## Update ConfigMap
  kubectl create configmap $CONFIG_MAP_NAME \
    --from-literal=status="$currentStatus" \
    --from-literal=message="$Message" \
    -o yaml --dry-run=client | kubectl replace -f -
fi

if [[ ${currentStatus} == "success" ]]; then
  exit 0
else
  exit 1
fi
