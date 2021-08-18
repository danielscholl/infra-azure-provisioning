#!/bin/bash

# This logs the Azure CLI in using the configured service principal.
az login --service-principal -u $PRINCIPAL_ID -p $PRINCIPAL_SECRET --tenant $TENANT_ID

# The Legal_COO.json file needs to be loaded into the Data Partition Storage Account,
# in the container  legal-service-azure-configuration.
ENV_VAULT=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query [].name -otsv)

IFS=',' read -r -a partitions <<< ${PARTITION_NAME_ARRAY}

for index in "${!partitions[@]}"
do
    echo "Ingesting file for partition: $index. ${partitions[index]}"
    
    STORAGE_ACCOUNT_NAME=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/${partitions[index]}-storage --query value -otsv)
    STORAGE_ACCOUNT_KEY=$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/${partitions[index]}-storage-key --query value -otsv)
    FILE_NAME=Legal_COO.json

    if [ -z "$STORAGE_ACCOUNT_NAME" -a "$STORAGE_ACCOUNT_NAME"==" " ]; then
        exit 1
    fi
    if [ -z "$STORAGE_ACCOUNT_KEY" -a "$STORAGE_ACCOUNT_KEY"==" " ]; then
        exit 1
    fi

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
            exit 1
        fi
    fi

    echo "File ingested for partition: $index. ${partitions[index]}"
    
done

