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

OSDU_URI=${OSDU_HOST}

if [[ ${OSDU_HOST} != "https://"* ]] || [[ ${OSDU_HOST} != "http://"* ]]; then
  OSDU_URI="https://${OSDU_HOST}"
fi

echo "Trying to Fetch Access Token"
ACCESS_TOKEN=$(sh ./get_access_token.sh)
if [[ "$ACCESS_TOKEN" == "TOKEN_FETCH_FAILURE" ]]; then
  currentStatus="failure"
  currentMessage="${currentMessage}. Failure fetching Access Token. "
else
  echo "Access Token fetched successfully."

  IFS=',' read -r -a partitions_array <<< ${PARTITIONS}
  
  partition_count=0
  partition_initialized_count=0

  az login --identity --username $OSDU_IDENTITY_ID
  if [ $? -eq 0 ]; then
      if [ ! -z "$SUBSCRIPTION" -a "$SUBSCRIPTION" != " " ]; then
        az account set --subscription $SUBSCRIPTION
      fi
  fi

  KEY_VAULT=$(az keyvault list --resource-group $RESOURCE_GROUP_NAME --query [].name -otsv)
  
  
  for index in "${!partitions_array[@]}"
  do
    partition_count=$(expr $partition_count + 1)
    echo "Intitializing Partition: ${partitions_array[index]}"
  
    OSDU_PARTITION_INIT_URI=${OSDU_URI}/api/partition/v1/partitions/${partitions_array[index]}
    echo "Partition Initialization Endpoint: ${OSDU_PARTITION_INIT_URI}"
  
    i=0
    partition_info_payload_content=`cat partition_init_api_payload.json`
    while [[ $i -lt 3 ]]; do
      i=$(expr $i + 1)
      dp_service_bus_namespace=$(az keyvault secret show --id https://${KEY_VAULT}.vault.azure.net/secrets/${partitions_array[index]}-sb-namespace --query value -otsv)
      if [ -z "$dp_service_bus_namespace" -a "$dp_service_bus_namespace"==" " ]; then
        echo "Getting service bus namespace Failed, Empty Reponse. Iteration $i."
        continue
      fi
      partition_info_payload_content_current=$partition_info_payload_content
      partition_info_payload_content_current=$(echo "$partition_info_payload_content_current" | sed "s/<service_bus_namespace>/$dp_service_bus_namespace/")
      echo -n "" > partition_init_api_payload.json
      echo "$partition_info_payload_content_current" >> partition_init_api_payload.json
  
      init_response=$(curl -s -w " Http_Status_Code:%{http_code} " \
        -X POST \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "data-partition-id: ${partitions_array[index]}" \
        -d "@partition_init_api_payload.json" \
        $OSDU_PARTITION_INIT_URI)
    
      echo -n "" > partition_init_api_payload.json
      echo "$partition_info_payload_content" >> partition_init_api_payload.json
      echo "Init Reponse: $init_response"
  
      if [ -z "$init_response" -a "$init_response"==" " ]; then
        echo "Initialization Failed, Empty Reponse. Iteration $i."
        continue
      fi
  
      # Status code check. succeed only if 2xx, or 409
      # quit for partition if 404 or 400.
      # 401 or 403, then retry after getting access token.
      # else sleep for 1min and retry
      if [[ ${init_response} != *"Http_Status_Code:2"* ]] && [[ ${init_response} != *"Http_Status_Code:409"* ]];then
        if [[ ${init_response} == *"Http_Status_Code:400"* ]] || [[ ${init_response} == *"Http_Status_Code:404"* ]];then
          currentStatus="failure"
          currentMessage="${currentMessage}. Partition Init for partition ${partitions_array[index]} failed with response $init_response. "
          echo "Partition Init for partition ${partitions_array[index]} failed with response $init_response"
          break
        fi
  
        echo "Sleeping for 1min."
        sleep 1m
  
        if [[ ${init_response} == *"Http_Status_Code:401"* ]] || [[ ${init_response} == *"Http_Status_Code:403"* ]];then
          echo "Trying to Re-Fetch Access Token"
          ACCESS_TOKEN=$(sh ./get_access_token.sh)
          if [[ "$ACCESS_TOKEN" == "TOKEN_FETCH_FAILURE" ]]; then
            currentStatus="failure"
            currentMessage="${currentMessage}. Failure re-fetching Access Token. "
            echo "Failure re-fetching Access Token"
            break
          fi
          echo "Access Token re-fetched successfully."
        fi
  
        continue
      else
        if [[ ${init_response} == *"Http_Status_Code:409"* ]];then
          currentMessage="${currentMessage}. HTTP Status Code: 409 -> Partition ${partitions_array[index]} Already Exists. "
          echo "HTTP Status Code: 409 -> Partition ${partitions_array[index]} Already Exists."
        fi
        currentMessage="${currentMessage}. Partition ${partitions_array[index]} Initialized successfully. "
        echo "Partition ${partitions_array[index]} Initialized successfully."
        partition_initialized_count=$(expr $partition_initialized_count + 1)
  
        break
      fi
    done

    if [[ $i -ge 3 ]]; then
      currentStatus="failure"
      currentMessage="${currentMessage}. Max Number of retries reached. "
    fi
  done
  
  if [ "$partition_count" -ne "$partition_initialized_count" ]; then
    currentStatus="failure"
    currentMessage="${currentMessage}. $partition_initialized_count partition(s) of total $partition_count partition(s) initialized successfully. "
    echo "$partition_initialized_count partition(s) of total $partition_count partition(s) initialized successfully."
  else
    currentMessage="${currentMessage}. All $partition_initialized_count partition(s) initialized successfully. "
    echo "All $partition_initialized_count partition(s) initialized successfully."
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

  Message="${Message}Partition Init Message: ${currentMessage}. "

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