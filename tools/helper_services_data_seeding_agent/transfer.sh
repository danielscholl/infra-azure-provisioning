#!/bin/bash

mkdir -p tmp
cd tmp
wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux && tar -xf azcopy_v10.tar.gz --strip-components=1
cp ./azcopy /usr/bin/
cd ..
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
CRS_CONVERSION_SOURCE_FOLDER="crs-conversion-service/apachesis_setup"
CRS_CATALOG_SOURCE_FOLDER="crs-catalog-service/data/crs_catalog_v2.json"
UNIT_SOURCE_FOLDER="unit-service/data/unit_catalog_v2.json"

max_retry_count=7
current_retry_count=0
loginStatus=1
while [ ${current_retry_count} -lt ${max_retry_count} ];
do
    az login --identity --username $OSDU_IDENTITY_ID
    if [ $? -eq 0 ]; then
      if [ -z "$SUBSCRIPTION" -a "$SUBSCRIPTION"==" " ]; then
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
STORAGE_ACCOUNT_NAME=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/airflow-storage --query value -otsv)
if [ -z "$STORAGE_ACCOUNT_NAME" -a "$STORAGE_ACCOUNT_NAME" == " " ]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. Storage Account Name Not Found. "
fi
STORAGE_ACCOUNT_KEY=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/airflow-storage-key --query value -otsv)
if [ -z "$STORAGE_ACCOUNT_KEY" -a "$STORAGE_ACCOUNT_KEY" == " " ]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. Storage Account Key Not Found. "
else

  EXPIRE=$(date -u -d "59 minutes" '+%Y-%m-%dT%H:%M:%SZ')
  START=$(date -u -d "-1 minute" '+%Y-%m-%dT%H:%M:%SZ')

  #Generating the SAS Token required for Authorization
  AZURE_STORAGE_SAS_TOKEN=$(az storage account generate-sas --account-name $STORAGE_ACCOUNT_NAME --account-key $STORAGE_ACCOUNT_KEY --start $START --expiry $EXPIRE --https-only --resource-types sco --services f --permissions cwdlur -o tsv)
  azcopy cp $CRS_CONVERSION_SOURCE_FOLDER "https://$STORAGE_ACCOUNT_NAME.file.core.windows.net/crs-conversion?${AZURE_STORAGE_SAS_TOKEN}" --recursive=true
  if [[ $? -gt 0 ]]; then
    currentStatus="failure"
    currentMessage="${currentMessage}. Failed to copy data to crs-conversion file share"
  fi
  azcopy cp $CRS_CATALOG_SOURCE_FOLDER "https://$STORAGE_ACCOUNT_NAME.file.core.windows.net/crs?${AZURE_STORAGE_SAS_TOKEN}" --recursive=true
  if [[ $? -gt 0 ]]; then
    currentStatus="failure"
    currentMessage="${currentMessage}. Failed to copy data to crs file share"
  fi
  azcopy cp $UNIT_SOURCE_FOLDER "https://$STORAGE_ACCOUNT_NAME.file.core.windows.net/unit?${AZURE_STORAGE_SAS_TOKEN}" --recursive=true
  if [[ $? -gt 0 ]]; then
    currentStatus="failure"
    currentMessage="${currentMessage}. Failed to copy data to unit file share"
  fi
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
