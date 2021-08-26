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

for index in "${!partitions_array[@]}"
do
  partition_count=$(expr $partition_count + 1)
  echo "Intitializing Partition: ${partitions_array[index]}"

  OSDU_PARTITION_INIT_URI=${OSDU_URI}/api/partition/v1/partitions/${partitions_array[index]}
  echo "Partition Initialization Endpoint: ${OSDU_PARTITION_INIT_URI}"

  i=0
  while [[ $i -lt 3 ]]; do
    i=$(expr $i + 1)

    init_response=$(curl -s -w " Http_Status_Code:%{http_code} " \
      -X POST \
      -H 'Content-Type: application/json' \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "data-partition-id: ${partitions_array[index]}" \
      -d "@partition_init_api_payload.json" \
      $OSDU_PARTITION_INIT_URI)
  
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
        echo "Partition Init for partition ${partitions_array[index]} failed with response $init_response"
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
      echo "Partition ${partitions_array[index]} Initialized successfully."
      partition_initialized_count=$(expr $partition_initialized_count + 1)

      break
    fi
  done
done

if [ "$partition_count" -ne "$partition_initialized_count" ]; then
  echo "$partition_initialized_count partition(s) of total $partition_count partition(s) initialized successfully."
  exit 1
else
 echo "All $partition_initialized_count partition(s) initialized successfully."
 exit 0
fi