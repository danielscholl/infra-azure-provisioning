#!/usr/bin/env bash
#
#  Purpose: Create the Developer Environment Variables.
#  Usage:
#    storage.sh

###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: DNS_HOST=<your_host> INVALID_JWT=<your_token> file.sh " 1>&2; exit 1; }

SERVICE="file"

if [ -z $UNIQUE ]; then
  tput setaf 1; echo 'ERROR: UNIQUE not provided' ; tput sgr0
  usage;
fi

if [ -z $DNS_HOST ]; then
  tput setaf 1; echo 'ERROR: DNS_HOST not provided' ; tput sgr0
  usage;
fi

if [ -z $COMMON_VAULT ]; then
  tput setaf 1; echo 'ERROR: COMMON_VAULT not provided' ; tput sgr0
  usage;
fi

if [ -z $INVALID_JWT ]; then
  tput setaf 1; echo 'ERROR: INVALID_JWT not provided' ; tput sgr0
  usage;
fi

if [ -f ./settings_common.env ]; then
  source ./settings_common.env;
else
  tput setaf 1; echo 'ERROR: common.env not found' ; tput sgr0
fi

if [ -f ./settings_environment.env ]; then
  source ./settings_environment.env;
else
  tput setaf 1; echo 'ERROR: environment.env not found' ; tput sgr0
fi

if [ ! -d $UNIQUE ]; then mkdir $UNIQUE; fi


# ------------------------------------------------------------------------------------------------------
# LocalHost Run Settings
# ------------------------------------------------------------------------------------------------------
LOG_PREFIX="file"
AZURE_TENANT_ID="${TENANT_ID}"
AZURE_CLIENT_ID="${ENV_PRINCIPAL_ID}"
AZURE_CLIENT_SECRET="${ENV_PRINCIPAL_SECRET}"
keyvault_url="${ENV_KEYVAULT}"
appinsights_key="${ENV_APPINSIGHTS_KEY}"
cosmosdb_database="${COSMOS_DB_NAME}"
AZURE_AD_APP_RESOURCE_ID="${ENV_APP_ID}"
osdu_entitlements_url="https://${ENV_HOST}/entitlements/v1"
osdu_entitlements_app_key="${API_KEY}"
osdu_storage_url="https://${ENV_HOST}/api/storage/v2/"
AZURE_STORAGE_ACCOUNT="${ENV_STORAGE}" # also used for testing
aad_client_id="${ENV_APP_ID}"
server_port="8082"
azure_istioauth_enabled="true"

# ------------------------------------------------------------------------------------------------------
# Integration Test Settings
# ------------------------------------------------------------------------------------------------------
FILE_SERVICE_HOST="http://localhost:${server_port}/api/file/v2"
FILE_SERVICE_HOST_REMOTE="https://${ENV_HOST}/api/file/v2"
DATA_PARTITION_ID="opendes"
INTEGRATION_TESTER="${ENV_PRINCIPAL_ID}"
TESTER_SERVICEPRINCIPAL_SECRET="${ENV_PRINCIPAL_SECRET}"
AZURE_AD_TENANT_ID="${TENANT_ID}"
AZURE_AD_APP_RESOURCE_ID="${ENV_APP_ID}"
NO_DATA_ACCESS_TESTER="${NO_ACCESS_ID}"
NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET="${NO_ACCESS_SECRET}"
USER_ID="osdu-user"
EXIST_FILE_ID="8900a83f-18c6-4b1d-8f38-309a208779cc"
TIME_ZONE="UTC+0"

cat > ${UNIQUE}/${SERVICE}.envrc <<LOCALENV
# ------------------------------------------------------------------------------------------------------
# Common Settings
# ------------------------------------------------------------------------------------------------------
export OSDU_TENANT=$OSDU_TENANT
export OSDU_TENANT2=$OSDU_TENANT2
export OSDU_TENANT3=$OSDU_TENANT3
export COMPANY_DOMAIN=$COMPANY_DOMAIN
export COSMOS_DB_NAME=$COSMOS_DB_NAME
export LEGAL_SERVICE_BUS_TOPIC=$LEGAL_SERVICE_BUS_TOPIC
export RECORD_SERVICE_BUS_TOPIC=$RECORD_SERVICE_BUS_TOPIC
export LEGAL_STORAGE_CONTAINER=$LEGAL_STORAGE_CONTAINER
export TENANT_ID=$TENANT_ID
export INVALID_JWT=$INVALID_JWT

export NO_ACCESS_ID=$NO_ACCESS_ID
export NO_ACCESS_SECRET=$NO_ACCESS_SECRET
export OTHER_APP_ID=$OTHER_APP_ID
export OTHER_APP_OID=$OTHER_APP_OID

export AD_USER_EMAIL=$AD_USER_EMAIL
export AD_USER_OID=$AD_USER_OID
export AD_GUEST_EMAIL=$AD_GUEST_EMAIL
export AD_GUEST_OID=$AD_GUEST_OID

# ------------------------------------------------------------------------------------------------------
# Environment Settings
# ------------------------------------------------------------------------------------------------------
export ENV_SUBSCRIPTION_NAME=$ENV_SUBSCRIPTION_NAME
export ENV_APP_ID=$ENV_APP_ID
export ENV_PRINCIPAL_ID=$ENV_PRINCIPAL_ID
export ENV_PRINCIPAL_SECRET=$ENV_PRINCIPAL_SECRET
export ENV_APPINSIGHTS_KEY=$ENV_APPINSIGHTS_KEY
export ENV_REGISTRY=$ENV_REGISTRY
export ENV_STORAGE=$ENV_STORAGE
export ENV_STORAGE_KEY=$ENV_STORAGE_KEY
export ENV_STORAGE_CONNECTION=$ENV_STORAGE_CONNECTION
export ENV_COSMOSDB_HOST=$ENV_COSMOSDB_HOST
export ENV_COSMOSDB_KEY=$ENV_COSMOSDB_KEY
export ENV_SERVICEBUS_NAMESPACE=$ENV_SERVICEBUS_NAMESPACE
export ENV_SERVICEBUS_CONNECTION=$ENV_SERVICEBUS_CONNECTION
export ENV_KEYVAULT=$ENV_KEYVAULT
export ENV_HOST=$ENV_HOST
export ENV_REGION=$ENV_REGION
export ENV_ELASTIC_HOST=$ENV_ELASTIC_HOST
export ENV_ELASTIC_PORT=$ENV_ELASTIC_PORT
export ENV_ELASTIC_USERNAME=$ENV_ELASTIC_USERNAME
export ENV_ELASTIC_PASSWORD=$ENV_ELASTIC_PASSWORD


# ------------------------------------------------------------------------------------------------------
# LocalHost Run Settings
# ------------------------------------------------------------------------------------------------------
export LOG_PREFIX="${LOG_PREFIX}"
export AZURE_TENANT_ID="${AZURE_TENANT_ID}"
export AZURE_CLIENT_ID="${AZURE_CLIENT_ID}"
export AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"
export keyvault_url="${keyvault_url}"
export appinsights_key="${appinsights_key}"
export cosmosdb_database="${cosmosdb_database}"
export AZURE_AD_APP_RESOURCE_ID="${AZURE_AD_APP_RESOURCE_ID}"
export osdu_entitlements_url="${osdu_entitlements_url}"
export osdu_entitlements_app_key="${osdu_entitlements_app_key}"
export osdu_storage_url="${osdu_storage_url}"
export AZURE_STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT}"
export aad_client_id="${aad_client_id}"
export server_port="${server_port}"
export azure_istioauth_enabled="${azure_istioauth_enabled}"

# ------------------------------------------------------------------------------------------------------
# Integration Test Settings
# ------------------------------------------------------------------------------------------------------
export FILE_SERVICE_HOST="${FILE_SERVICE_HOST}"
export DATA_PARTITION_ID="${DATA_PARTITION_ID}"
export INTEGRATION_TESTER="${INTEGRATION_TESTER}"
export TESTER_SERVICEPRINCIPAL_SECRET="${TESTER_SERVICEPRINCIPAL_SECRET}"
export AZURE_AD_TENANT_ID="${AZURE_AD_TENANT_ID}"
export AZURE_AD_APP_RESOURCE_ID="${AZURE_AD_APP_RESOURCE_ID}"
export NO_DATA_ACCESS_TESTER="${NO_DATA_ACCESS_TESTER}"
export NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET="${NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET}"
export AZURE_STORAGE_ACCOUNT="${AZURE_STORAGE_ACCOUNT}"
export USER_ID="${USER_ID}"
export EXIST_FILE_ID="${EXIST_FILE_ID}"
export TIME_ZONE="${TIME_ZONE}"
LOCALENV


cat > ${UNIQUE}/${SERVICE}_local.yaml <<LOCALRUN
LOG_PREFIX: "${LOG_PREFIX}"
AZURE_TENANT_ID: "${AZURE_TENANT_ID}"
AZURE_CLIENT_ID: "${AZURE_CLIENT_ID}"
AZURE_CLIENT_SECRET: "${AZURE_CLIENT_SECRET}"
keyvault_url: "${keyvault_url}"
appinsights_key: "${appinsights_key}"
cosmosdb_database: "${cosmosdb_database}"
AZURE_AD_APP_RESOURCE_ID: "${AZURE_AD_APP_RESOURCE_ID}"
osdu_entitlements_url: "${osdu_entitlements_url}"
osdu_entitlements_app_key: "${osdu_entitlements_app_key}"
osdu_storage_url: "${osdu_storage_url}"
AZURE_STORAGE_ACCOUNT: "${AZURE_STORAGE_ACCOUNT}"
aad_client_id: "${aad_client_id}"
server_port: "${server_port}"
azure_istioauth_enabled: "${azure_istioauth_enabled}"
LOCALRUN


cat > ${UNIQUE}/${SERVICE}_local_test.yaml <<LOCALTEST
FILE_SERVICE_HOST: "${FILE_SERVICE_HOST}"
DATA_PARTITION_ID: "${DATA_PARTITION_ID}"
INTEGRATION_TESTER: "${INTEGRATION_TESTER}"
TESTER_SERVICEPRINCIPAL_SECRET: "${TESTER_SERVICEPRINCIPAL_SECRET}"
AZURE_AD_TENANT_ID: "${AZURE_AD_TENANT_ID}"
AZURE_AD_APP_RESOURCE_ID: "${AZURE_AD_APP_RESOURCE_ID}"
NO_DATA_ACCESS_TESTER: "${NO_DATA_ACCESS_TESTER}"
NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET: "${NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET}"
AZURE_STORAGE_ACCOUNT: "${AZURE_STORAGE_ACCOUNT}"
USER_ID: "${USER_ID}"
EXIST_FILE_ID: "${EXIST_FILE_ID}"
TIME_ZONE: "${TIME_ZONE}"
LOCALTEST


cat > ${UNIQUE}/${SERVICE}_test.yaml <<DEVTEST
FILE_SERVICE_HOST: "${FILE_SERVICE_HOST_REMOTE}"
DATA_PARTITION_ID: "${DATA_PARTITION_ID}"
INTEGRATION_TESTER: "${INTEGRATION_TESTER}"
TESTER_SERVICEPRINCIPAL_SECRET: "${TESTER_SERVICEPRINCIPAL_SECRET}"
AZURE_AD_TENANT_ID: "${AZURE_AD_TENANT_ID}"
AZURE_AD_APP_RESOURCE_ID: "${AZURE_AD_APP_RESOURCE_ID}"
NO_DATA_ACCESS_TESTER: "${NO_DATA_ACCESS_TESTER}"
NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET: "${NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET}"
AZURE_STORAGE_ACCOUNT: "${AZURE_STORAGE_ACCOUNT}"
USER_ID: "${USER_ID}"
EXIST_FILE_ID: "${EXIST_FILE_ID}"
TIME_ZONE: "${TIME_ZONE}"
DEVTEST
