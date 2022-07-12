#!/usr/bin/env bash
#
#  Purpose: Create the Developer Environment Variables.
#  Usage:
#    eds-dms.sh

###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: DNS_HOST=<your_host> INVALID_JWT=<your_token> eds-dms.sh " 1>&2; exit 1; }

SERVICE="eds-dms"

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
LOG_PREFIX="eds-dms"
AZURE_TENANT_ID="${TENANT_ID}"
AZURE_CLIENT_ID="${ENV_PRINCIPAL_ID}"
AZURE_CLIENT_SECRET="${ENV_PRINCIPAL_SECRET}"
KEY_VAULT_URL="${ENV_KEYVAULT}"
appinsights_key="${ENV_APPINSIGHTS_KEY}"
cosmosdb_database="${COSMOS_DB_NAME}"
aad_client_id="${ENV_APP_ID}"
AUTHORIZE_API="https://${ENV_HOST}/api/entitlements/v2"
entitlements_app_key="${API_KEY}"
STORAGE_API="https://${ENV_HOST}/api/storage/v2/"
SECRET_API="https://${ENV_HOST}/api/secret/v1/"
PARTITION_API="https://${ENV_HOST}/api/partition/v1"
schema_service_endpoint="https://${ENV_HOST}/api/schema-service/v1"
azure_istioauth_enabled="false"
server_port="8089"


# ------------------------------------------------------------------------------------------------------
# Integration Test Settings
# ------------------------------------------------------------------------------------------------------
EDSDMS_BASE_URL="http://localhost:${server_port}/api/eds/v1/"
DATASET_BASE_URL="http://${ENV_HOST}/api/dataset/v1/"
SCHEMA_BASE_URL="https://${ENV_HOST}/api/schema-service/v1/"
STORAGE_BASE_URL="https://${ENV_HOST}/api/storage/v2/"
LEGAL_BASE_URL="https://${ENV_HOST}/api/legal/v1/"
SECRET_BASE_URL="https://${ENV_HOST}/api/secret/v1/"
AZURE_STORAGE_ACCOUNT="${ENV_STORAGE}" # also used for testing
DATA_PARTITION_ID="opendes"
INTEGRATION_TESTER="${ENV_PRINCIPAL_ID}"
TESTER_SERVICEPRINCIPAL_SECRET="${ENV_PRINCIPAL_SECRET}"
AZURE_AD_TENANT_ID="${TENANT_ID}"
AZURE_AD_APP_RESOURCE_ID="${ENV_APP_ID}"
NO_DATA_ACCESS_TESTER="${NO_ACCESS_ID}"
NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET="${NO_ACCESS_SECRET}"
EXTERNAL_DATASET_CLIENT_ID="${ENV_PRINCIPAL_ID}"
EXTERNAL_DATASET_CLIENT_SECRET_KEY="${ENV_PRINCIPAL_SECRET}"
EXTERNAL_DATASET_SCOPES_KEY="openid"
EXTERNAL_DATASET_CLIENT_SECRET_VALUE="${ENV_PRINCIPAL_SECRET}"
EXTERNAL_DATASET_SCOPES_VALUE="openid"
EXTERNAL_DATASET_TOKEN_URL="xxxxx"
AZURE_STORAGE_ACCOUNT="${ENV_STORAGE}"
USER_ID="osdu-user"
TENANT_NAME="opendes"
DOMAIN="${COMPANY_DOMAIN}"
DEPLOY_ENV="empty"

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
export LOG_PREFIX="eds-dms"
export AZURE_TENANT_ID="${TENANT_ID}"
export AZURE_CLIENT_ID="${ENV_PRINCIPAL_ID}"
export AZURE_CLIENT_SECRET="${ENV_PRINCIPAL_SECRET}"
export KEY_VAULT_URL="${ENV_KEYVAULT}"
export appinsights_key="${ENV_APPINSIGHTS_KEY}"
export cosmosdb_database="${COSMOS_DB_NAME}"
export aad_client_id="${ENV_APP_ID}"
export AUTHORIZE_API="https://${ENV_HOST}/api/entitlements/v2"
export entitlements_app_key="${API_KEY}"
export STORAGE_API="https://${ENV_HOST}/api/storage/v2/"
export SECRET_API="https://${ENV_HOST}/api/secret/v1/"
export PARTITION_API="https://${ENV_HOST}/api/partition/v1"
export schema_service_endpoint="https://${ENV_HOST}/api/schema-service/v1"
export azure_istioauth_enabled="false"
export server_port="8089"


# ------------------------------------------------------------------------------------------------------
# Integration Test Settings
# ------------------------------------------------------------------------------------------------------
export EDSDMS_BASE_URL="http://localhost:${server_port}/api/dms/eds/v1/"
export DATASET_BASE_URL="http://${ENV_HOST}/api/dataset/v1/"
export SCHEMA_BASE_URL="https://${ENV_HOST}/api/schema-service/v1/"
export export _BASE_URL="https://${ENV_HOST}/api/export /v2/"
export LEGAL_BASE_URL="https://${ENV_HOST}/api/legal/v1/"
export SECRET_BASE_URL="https://${ENV_HOST}/api/secret/v1/"
export AZURE_export _ACCOUNT="${ENV_export }" # also used for testing
export DATA_PARTITION_ID="opendes"
export INTEGRATION_TESTER="${ENV_PRINCIPAL_ID}"
export TESTER_SERVICEPRINCIPAL_SECRET="${ENV_PRINCIPAL_SECRET}"
export AZURE_AD_TENANT_ID="${TENANT_ID}"
export AZURE_AD_APP_RESOURCE_ID="${ENV_APP_ID}"
export NO_DATA_ACCESS_TESTER="${NO_ACCESS_ID}"
export NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET="${NO_ACCESS_SECRET}"
export EXTERNAL_DATASET_CLIENT_ID="${ENV_PRINCIPAL_ID}"
export EXTERNAL_DATASET_CLIENT_SECRET_KEY="${ENV_PRINCIPAL_SECRET}"
export EXTERNAL_DATASET_SCOPES_KEY="openid"
export EXTERNAL_DATASET_CLIENT_SECRET_VALUE="${ENV_PRINCIPAL_SECRET}"
export EXTERNAL_DATASET_SCOPES_VALUE="openid"
export EXTERNAL_DATASET_TOKEN_URL="xxxxx"
export AZURE_export _ACCOUNT="${ENV_export }"
export USER_ID="osdu-user"
export TENANT_NAME="opendes"
export DOMAIN="${COMPANY_DOMAIN}"
export DEPLOY_ENV="empty"
LOCALENV


cat > ${UNIQUE}/${SERVICE}_local.yaml <<LOCALRUN
LOG_PREFIX="eds-dms"
AZURE_TENANT_ID="${TENANT_ID}"
AZURE_CLIENT_ID="${ENV_PRINCIPAL_ID}"
AZURE_CLIENT_SECRET="${ENV_PRINCIPAL_SECRET}"
KEY_VAULT_URL="${ENV_KEYVAULT}"
appinsights_key="${ENV_APPINSIGHTS_KEY}"
cosmosdb_database="${COSMOS_DB_NAME}"
aad_client_id="${ENV_APP_ID}"
AUTHORIZE_API="https://${ENV_HOST}/api/entitlements/v2"
entitlements_app_key="${API_KEY}"
STORAGE_API="https://${ENV_HOST}/api/storage/v2/"
SECRET_API="https://${ENV_HOST}/api/secret/v1/"
PARTITION_API="https://${ENV_HOST}/api/partition/v1"
schema_service_endpoint="https://${ENV_HOST}/api/schema-service/v1"
azure_istioauth_enabled="false"
server_port="8089"
LOCALRUN


cat > ${UNIQUE}/${SERVICE}_local_test.yaml <<LOCALTEST
EDSDMS_BASE_URL="http://localhost:${server_port}/api/dms/eds/v1/"
DATASET_BASE_URL="http://${ENV_HOST}/api/dataset/v1/"
SCHEMA_BASE_URL="https://${ENV_HOST}/api/schema-service/v1/"
STORAGE_BASE_URL="https://${ENV_HOST}/api/storage/v2/"
LEGAL_BASE_URL="https://${ENV_HOST}/api/legal/v1/"
SECRET_BASE_URL="https://${ENV_HOST}/api/secret/v1/"
AZURE_STORAGE_ACCOUNT="${ENV_STORAGE}" # also used for testing
DATA_PARTITION_ID="opendes"
INTEGRATION_TESTER="${ENV_PRINCIPAL_ID}"
TESTER_SERVICEPRINCIPAL_SECRET="${ENV_PRINCIPAL_SECRET}"
AZURE_AD_TENANT_ID="${TENANT_ID}"
AZURE_AD_APP_RESOURCE_ID="${ENV_APP_ID}"
NO_DATA_ACCESS_TESTER="${NO_ACCESS_ID}"
NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET="${NO_ACCESS_SECRET}"
EXTERNAL_DATASET_CLIENT_ID="${ENV_PRINCIPAL_ID}"
EXTERNAL_DATASET_CLIENT_SECRET_KEY="${ENV_PRINCIPAL_SECRET}"
EXTERNAL_DATASET_SCOPES_KEY="openid"
EXTERNAL_DATASET_CLIENT_SECRET_VALUE="${ENV_PRINCIPAL_SECRET}"
EXTERNAL_DATASET_SCOPES_VALUE="openid"
EXTERNAL_DATASET_TOKEN_URL="xxxxx"
AZURE_STORAGE_ACCOUNT="${ENV_STORAGE}"
USER_ID="osdu-user"
TENANT_NAME="opendes"
DOMAIN="${COMPANY_DOMAIN}"
DEPLOY_ENV="empty"
LOCALTEST


cat > ${UNIQUE}/${SERVICE}_test.yaml <<DEVTEST
EDSDMS_BASE_URL="http://localhost:${server_port}/api/dms/eds/v1/"
DATASET_BASE_URL="http://${ENV_HOST}/api/dataset/v1/"
SCHEMA_BASE_URL="https://${ENV_HOST}/api/schema-service/v1/"
STORAGE_BASE_URL="https://${ENV_HOST}/api/storage/v2/"
LEGAL_BASE_URL="https://${ENV_HOST}/api/legal/v1/"
SECRET_BASE_URL="https://${ENV_HOST}/api/secret/v1/"
AZURE_STORAGE_ACCOUNT="${ENV_STORAGE}" # also used for testing
DATA_PARTITION_ID="opendes"
INTEGRATION_TESTER="${ENV_PRINCIPAL_ID}"
TESTER_SERVICEPRINCIPAL_SECRET="${ENV_PRINCIPAL_SECRET}"
AZURE_AD_TENANT_ID="${TENANT_ID}"
AZURE_AD_APP_RESOURCE_ID="${ENV_APP_ID}"
NO_DATA_ACCESS_TESTER="${NO_ACCESS_ID}"
NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET="${NO_ACCESS_SECRET}"
EXTERNAL_DATASET_CLIENT_ID="${ENV_PRINCIPAL_ID}"
EXTERNAL_DATASET_CLIENT_SECRET_KEY="${ENV_PRINCIPAL_SECRET}"
EXTERNAL_DATASET_SCOPES_KEY="openid"
EXTERNAL_DATASET_CLIENT_SECRET_VALUE="${ENV_PRINCIPAL_SECRET}"
EXTERNAL_DATASET_SCOPES_VALUE="openid"
EXTERNAL_DATASET_TOKEN_URL="xxxxx"
AZURE_STORAGE_ACCOUNT="${ENV_STORAGE}"
USER_ID="osdu-user"
TENANT_NAME="opendes"
DOMAIN="${COMPANY_DOMAIN}"
DEPLOY_ENV="empty"
DEVTEST
