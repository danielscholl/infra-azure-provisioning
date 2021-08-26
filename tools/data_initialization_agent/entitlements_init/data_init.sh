#!/bin/bash

OSDU_URI=${OSDU_HOST}

if [[ ${OSDU_HOST} != "https://"* ]] || [[ ${OSDU_HOST} != "http://"* ]]; then
  OSDU_URI="https://${OSDU_HOST}"
fi

echo "Trying to Fetch Access Token"
ACCESS_TOKEN=$(sh ./get_access_token.sh)
if [[ "$ACCESS_TOKEN" == "TOKEN_FETCH_FAILURE" ]]; then
  echo "Failure fetching Access Token"
  exit 1
fi
echo "Access Token fetched successfully."

IFS=',' read -r -a partitions_array <<< ${PARTITIONS}

partition_count=0
partition_initialized_count=0
partition_admin_initialized_count=0

for index in "${!partitions_array[@]}"
do
  partition_count=$(expr $partition_count + 1)
  echo "Intitializing Entitlements for Partition: ${partitions_array[index]}"

  OSDU_ENTITLEMENTS_INIT_URI=${OSDU_URI}/api/entitlements/v2/tenant-provisioning
  echo "Entitlements Partition Initialization Endpoint: ${OSDU_ENTITLEMENTS_INIT_URI}"

  i=0
  partition_initialized=false
  while [[ $i -lt 3 ]]; do
    i=$(expr $i + 1)

    init_response=$(curl -s -w " Http_Status_Code:%{http_code} " \
      -X POST \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "data-partition-id: ${partitions_array[index]}" \
      $OSDU_ENTITLEMENTS_INIT_URI)
  
    echo "Init Reponse: $init_response"

    if [ -z "$init_response" -a "$init_response"==" " ]; then
      echo "Initialization Failed, Empty Reponse. Iteration $i."
      continue
    fi

    # Status code check. succeed only if 2xx
    # quit for partition if 404 or 400.
    # 401 or 403, then retry after getting access token.
    # else sleep for 1min and retry
    if [[ ${init_response} != *"Http_Status_Code:2"* ]];then
      if [[ ${init_response} == *"Http_Status_Code:400"* ]] || [[ ${init_response} == *"Http_Status_Code:404"* ]];then
        echo "Entitlements Init for partition ${partitions_array[index]} failed with response $init_response"
        break
      fi

      echo "Sleeping for 1min."
      sleep 1m

      if [[ ${init_response} == *"Http_Status_Code:401"* ]] || [[ ${init_response} == *"Http_Status_Code:403"* ]];then
        echo "Trying to Re-Fetch Access Token"
        ACCESS_TOKEN=$(sh ./get_access_token.sh)
        if [[ "$ACCESS_TOKEN" == "TOKEN_FETCH_FAILURE" ]]; then
          echo "Failure re-fetching Access Token"
          exit 1
        fi
        echo "Access Token re-fetched successfully."
      fi

      continue
    else
      echo "Entitlements for Partition ${partitions_array[index]} Initialized successfully."
      partition_initialized_count=$(expr $partition_initialized_count + 1)
      partition_initialized=true

      break
    fi
  done

  if [ "$partition_initialized" != true ] ; then
    continue
  fi

  OSDU_ENTITLEMENTS_ADD_OPS_URI=${OSDU_URI}/api/entitlements/v2/groups/users.datalake.ops@${partitions_array[index]}.$SERVICE_DOMAIN/members
  echo "Entitlements Partition Add Ops Endpoint: ${OSDU_ENTITLEMENTS_ADD_OPS_URI}"

  i=0
  while [[ $i -lt 3 ]]; do
    i=$(expr $i + 1)

    init_response=$(curl -s -w " Http_Status_Code:%{http_code} " \
      -X POST \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "data-partition-id: ${partitions_array[index]}" \
      -d "{"email":"$ADMIN_ID", "role": "MEMBER"}" \
      $OSDU_ENTITLEMENTS_ADD_OPS_URI)
    
    echo "Init Reponse: $init_response"

    if [ -z "$init_response" -a "$init_response"==" " ]; then
      echo "Add Ops Member Failed, Empty Reponse. Iteration $i."
      continue
    fi

    # Status code check. succeed only if 2xx
    # quit for partition if 404 or 400.
    # 401 or 403, then retry after getting access token.
    # else sleep for 1min and retry
    if [[ ${init_response} != *"Http_Status_Code:2"* ]];then
      if [[ ${init_response} == *"Http_Status_Code:400"* ]] || [[ ${init_response} == *"Http_Status_Code:404"* ]];then
        echo "Add Ops Member for partition ${partitions_array[index]} failed with response $init_response"
        break
      fi

      echo "Sleeping for 1min."
      sleep 1m

      if [[ ${init_response} == *"Http_Status_Code:401"* ]] || [[ ${init_response} == *"Http_Status_Code:403"* ]];then
        echo "Trying to Re-Fetch Access Token"
        ACCESS_TOKEN=$(sh ./get_access_token.sh)
        if [[ "$ACCESS_TOKEN" == "TOKEN_FETCH_FAILURE" ]]; then
          echo "Failure re-fetching Access Token"
          exit 1
        fi
        echo "Access Token re-fetched successfully."
      fi

      continue
    else
      echo "Ops Member for Partition ${partitions_array[index]} Initialized successfully."
      partition_admin_initialized_count=$(expr $partition_admin_initialized_count + 1)

      break
    fi
  done
done

if [ "$partition_count" -ne "$partition_initialized_count" ] || [ "$partition_admin_initialized_count" -ne "$partition_initialized_count" ]; then
  echo "Entitlements for $partition_initialized_count partition(s) of total $partition_count partition(s) initialized successfully."
  echo "$partition_admin_initialized_count partition(s) of total $partition_initialized_count initialized with Ops Member."
  exit 1
else
  echo "Entitlements for All $partition_initialized_count partition(s) initialized successfully."
  echo "Ops Members for all of $partition_admin_initialized_count partition(s) added successfully."
  exit 0
fi