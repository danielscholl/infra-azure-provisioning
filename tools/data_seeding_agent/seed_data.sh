#!/bin/bash

currentStatus=""
currentMessage=""
retryCount=0
maxRetry=7
loginAttemptCount=0

while [[ $loginAttemptCount -lt $maxRetry ]]; do
    loginAttemptCount=$(expr $loginAttemptCount + 1)

    echo "Trying to Fetch Access Token"
    ACCESS_TOKEN=$(sh ./get_access_token.sh)
    if [[ "$ACCESS_TOKEN" == "TOKEN_FETCH_FAILURE" ]]; then
        echo "Failure manually fetching Access Token. Attempt ${loginAttemptCount} of ${maxRetry}."
        currentMessage="${currentMessage}. Failure manually fetching Access Token. Attempt ${loginAttemptCount} of ${maxRetry}. "
        continue
    else
        echo "Manual fetch access token successful. Attempt ${loginAttemptCount} of ${maxRetry}."
        currentMessage="${currentMessage}. Manual fetch access token successful. Attempt ${loginAttemptCount} of ${maxRetry}. "
        AZ_LOGIN=$(az login --identity --username $OSDU_IDENTITY_ID)
        echo $AZ_LOGIN

        if [[ ${AZ_LOGIN} == *"AzureConnectionError"* ]] || [[ ${AZ_LOGIN} == *"Failed to connect to MSI"* ]];then
            echo "az login failed. Attempt ${loginAttemptCount} of ${maxRetry}."
            currentMessage="${currentMessage}. az login failed: ${AZ_LOGIN}. Attempt ${loginAttemptCount} of ${maxRetry}. "
            continue
        else
            echo "az login successful. Attempt ${loginAttemptCount} of ${maxRetry}."
            currentMessage="${currentMessage}. az login successful. Attempt ${loginAttemptCount} of ${maxRetry}. "
            break
        fi
    fi
done

# The Legal_COO.json file needs to be loaded into the Data Partition Storage Account,
# in the container  legal-service-azure-configuration.
ENV_VAULT=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query [].name -otsv)

IFS=',' read -r -a partitions_array <<< ${PARTITIONS}

while [[ $retryCount -lt $maxRetry ]]; do

    retryCount=$(expr $retryCount + 1)
    for index in "${!partitions_array[@]}"
    do
        echo "Ingesting Legal_COO.json file for partition: $index. ${partitions_array[index]}"
        
        STORAGE_ACCOUNT_NAME=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/${partitions_array[index]}-storage --query value -otsv)
        STORAGE_ACCOUNT_KEY=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/${partitions_array[index]}-storage-key --query value -otsv)
        FILE_NAME=Legal_COO.json
    
        if [ -z "$STORAGE_ACCOUNT_NAME" -a "$STORAGE_ACCOUNT_NAME"==" " ]; then
            currentStatus="failure"
            currentMessage="${currentMessage}. Storage Account Name Not Found, Partition ${partitions_array[index]}. "
        fi
        if [ -z "$STORAGE_ACCOUNT_KEY" -a "$STORAGE_ACCOUNT_KEY"==" " ]; then
            currentStatus="failure"
            currentMessage="${currentMessage}. Storage Account Key Not Found, Partition ${partitions_array[index]}. "
        else
            az storage blob upload \
                --account-name $STORAGE_ACCOUNT_NAME \
                --account-key $STORAGE_ACCOUNT_KEY \
                --file ./test_data/Legal_COO.json \
                --container-name legal-service-azure-configuration \
                --name $FILE_NAME
    
            BLOB_LIST=$(az storage blob list \
                --account-name $STORAGE_ACCOUNT_NAME \
                --account-key $STORAGE_ACCOUNT_KEY \
                --container-name legal-service-azure-configuration \
                --query "[].{name:name}" -otsv)
    
            if [[ ! " ${BLOB_LIST[@]} " =~ " ${FILE_NAME} " ]]; then
            
                sleep 1m
    
                az storage blob upload \
                    --account-name $STORAGE_ACCOUNT_NAME \
                    --account-key $STORAGE_ACCOUNT_KEY \
                    --file ./test_data/Legal_COO.json \
                    --container-name legal-service-azure-configuration \
                    --name $FILE_NAME
    
                BLOB_LIST=$(az storage blob list \
                    --account-name $STORAGE_ACCOUNT_NAME \
                    --account-key $STORAGE_ACCOUNT_KEY \
                    --container-name legal-service-azure-configuration \
                    --query "[].{name:name}" -otsv)
    
                if [[ ! " ${BLOB_LIST[@]} " =~ " ${FILE_NAME} " ]]; then
                    currentStatus="failure"
                    currentMessage="${currentMessage}. Legal_COO.json File ingestion FAILED, Partition ${partitions_array[index]}. "
                else
                    currentMessage="${currentMessage}. Legal_COO.json File ingested, Partition: ${partitions_array[index]}. "
                fi
            else
                currentMessage="${currentMessage}. Legal_COO.json File ingested, Partition: ${partitions_array[index]}. "
            fi
        fi
        
        echo "Legal_COO.json File ingested for partition: $index. ${partitions_array[index]}"
        echo "Ingesting tenant_info_*.json file(s) for partition: $index. ${partitions_array[index]}"
    
        export COSMOS_ENDPOINT=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/${partitions_array[index]}-cosmos-endpoint --query value -otsv)
        export COSMOS_KEY=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/${partitions_array[index]}-cosmos-primary-key --query value -otsv)
    
        if [ -z "$COSMOS_ENDPOINT" -a "$COSMOS_ENDPOINT"==" " ]; then
            currentStatus="failure"
            currentMessage="${currentMessage}. COSMOS_ENDPOINT Not Found, Partition ${partitions_array[index]}. "
        fi
        if [ -z "$COSMOS_KEY" -a "$COSMOS_KEY"==" " ]; then
            currentStatus="failure"
            currentMessage="${currentMessage}. COSMOS_KEY Not Found, Partition ${partitions_array[index]}. "
        else
            python3 ./test_data/upload-data.py
            currentMessage="${currentMessage}. Tenant Info Files ingested, Partition: ${partitions_array[index]}. "
        fi
        
        echo "tenant_info_*.json File(s) ingested for partition: $index. ${partitions_array[index]}"
    done

    if [ -z "$currentStatus" -a "$currentStatus"==" " ]; then
        break
    elif [[ $retryCount -ge $maxRetry ]]; then
        currentMessage="${currentMessage}. Iteration not successful, Retry Count: $retryCount."
        echo "Iteration not successful, Retry Count: $retryCount, Aborting..."
    else
        currentStatus=""
        currentMessage="${currentMessage}. Iteration not successful, Retry Count: $retryCount, Retrying..."
        echo "Iteration not successful, Retry Count: $retryCount, Retrying..."
    fi
done

if [ -z "$currentStatus" -a "$currentStatus"==" " ]; then
    currentStatus="success"
fi
echo "Current Status: ${currentStatus}"
echo "Current Message: ${currentMessage}"

if [ ! -z "$CONFIG_MAP_NAME" -a "$CONFIG_MAP_NAME" != " " ]; then
  az login --identity --username $OSDU_IDENTITY_ID
  ENV_AKS=$(az aks list --resource-group $RESOURCE_GROUP_NAME --query [].name -otsv)
  az aks get-credentials --resource-group $RESOURCE_GROUP_NAME --name $ENV_AKS
  kubectl config set-context $RESOURCE_GROUP_NAME --cluster $ENV_AKS

  Status=$(kubectl get configmap $CONFIG_MAP_NAME -o jsonpath='{.data.status}')
  Message=$(kubectl get configmap $CONFIG_MAP_NAME -o jsonpath='{.data.message}')

  Message="${Message}Static File Data Seeding Message: ${currentMessage}. "

  ## Update ConfigMap
  kubectl create configmap $CONFIG_MAP_NAME \
    --from-literal=status="$currentStatus" \
    --from-literal=message="$Message" \
    -o yaml --dry-run=client | kubectl replace -f -
fi

if [[ ${currentStatus} == "success" ]]; then
    exit 0
elif [[ ${currentStatus} == "failure" ]]; then
    exit 1
else
    exit 1
fi