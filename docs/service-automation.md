# Create OSDU Service Libraries

__Setup and Configure the ADO Library `Azure - OSDU`__

This variable group will be used to hold the common values for the services to be deployed and relate specifically to settings common to integration tests across all services.  Variable values here that are other variables are being pulled from the Library group accessing the common Key Vault.

| Variable                                      | Value |
|-----------------------------------------------|-------|
| ADMIN_EMAIL                                   | <your_sslcert_admin_email>                |
| AGENT_POOL                                    | `Hosted Ubuntu 1604`                      |
| AZURE_AD_GUEST_EMAIL                          | `$(ad-guest-email)`                       |
| AZURE_AD_GUEST_OID                            | `$(ad-guest-oid)`                         |
| AZURE_AD_OTHER_APP_RESOURCE_ID                | `$(osdu-mvp-<your_unique>-application-clientid)` |
| AZURE_AD_OTHER_APP_RESOURCE_OID               | `$(osdu-mvp-<your_unique>-application-oid)`|
| AZURE_AD_USER_EMAIL                           | `$(ad-user-email)`                        |
| AZURE_AD_USER_OID                             | `$(ad-user-oid)`                          |
| AZURE_LEGAL_TOPICNAME                         | `legaltags`                               |
| DEPLOY_ENV                                    | `empty`                                   |
| ENTITLEMENT_URL                               | `https://<your_fqdn>/entitlements/v1/`    |
| EXPIRED_TOKEN                                 | <an_expired_token>                        |
| HOST_URL                                      | `https://<your_fqdn>/`                    |
| LEGAL_URL                                     | `https://<your_fqdn>/api/legal/v1/`       |
| NO_DATA_ACCESS_TESTER                         | `$(osdu-mvp-<your_unique>-noaccess-clientid)`  |
| NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET | `$(osdu-mvp-<your_unique>-noaccess-secret)`   |
| PUBSUB_TOKEN                                  | `az`                                      |
| SERVICE_CONNECTION_NAME                       | <your_service_connection_name>            |
| GOOGLE_CLOUD_PROJECT                          | `opendes`                                 |


```bash
ADMIN_EMAIL="<your_cert_admin>"     # ie: admin@email.com
DNS_HOST="<your_ingress_hostname>"  # ie: osdu.contoso.com
SERVICE_CONNECTION_NAME=osdu-mvp-$UNIQUE
INVALID_TOKEN="<an_invalid_token>"

az pipelines variable-group create \
  --name "Azure - OSDU" \
  --authorize true \
  --variables \
  ADMIN_EMAIL=$ADMIN_EMAIL \
  AGENT_POOL="Hosted Ubuntu 1604" \
  AZURE_AD_GUEST_EMAIL='$(ad-guest-email)' \
  AZURE_AD_GUEST_OID='$(ad-guest-oid)' \
  AZURE_AD_OTHER_APP_RESOURCE_ID='$(osdu-mvp-'${UNIQUE}'-application-clientid)' \
  AZURE_AD_OTHER_APP_RESOURCE_OID='$(osdu-mvp-'${UNIQUE}'-application-oid)' \
  AZURE_AD_USER_EMAIL='$(ad-user-email)' \
  AZURE_AD_USER_OID='$(ad-user-oid)' \
  AZURE_LEGAL_TOPICNAME="legaltags" \
  DEPLOY_ENV="empty" \
  ENTITLEMENT_URL="https://${DNS_HOST}/entitlements/v1/" \
  EXPIRED_TOKEN=$INVALID_TOKEN \
  HOST_URL="https://${DNS_HOST}/" \
  LEGAL_URL="https://${DNS_HOST}/api/legal/v1/" \
  NO_DATA_ACCESS_TESTER='$(osdu-mvp-'${UNIQUE}'-noaccess-clientid)' \
  NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET='$(osdu-mvp-'${UNIQUE}'-noaccess-secret))' \
  PUBSUB_TOKEN="az" \
  SERVICE_CONNECTION_NAME=$SERVICE_CONNECTION_NAME \
  GOOGLE_CLOUD_PROJECT="opendes" \
  -ojson
```


__Setup and Configure the ADO Library `Azure - OSDU Secrets`__

This variable group is a linked variable group that links to the Common Key Vault `osducommon<random>` and retrieves secret common settings.

- ad-guest-email
- ad-guest-oid
- ad-user-email
- ad-user-oid
- istio-username
- istio-password
- osdu-mvp-{unique}-application-clientid
- osdu-mvp-{unique}-application-secret
- osdu-infra-{unique}-noaccess-clientid
- osdu-infra-{unique}-noaccess-oid


__Setup and Configure the ADO Library `Azure Target Env - demo`__

This variable group will be used to hold the specific environment values necessary for integration testing of the services being deployed. Variable values here that are other variables are being pulled from the Library group accessing the environment Key Vault.

| Variable | Value |
|----------|-------|
| AZURE_AD_APP_RESOURCE_ID                      | `$(aad-client-id)`                |
| AZURE_DEPLOY_SUBSCRIPTION                     | `$(subscription-id)`              |
| AZURE_LEGAL_SERVICEBUS                        | `$(opendes-sb-connection)`        |
| AZURE_TENANT_ID                               | `$(tenant-id)`                    |
| AZURE_TESTER_SERVICEPRINCIPAL_SECRET          | `$(app-dev-sp-password)`          |
| CONTAINER_REGISTRY_NAME                       | `$(container_registry)`           |
| DNS_HOST                                      | <your_FQDN>                       |
| DOMAIN                                        | `contoso.com`                     |
| ELASTIC_ENDPOINT                              | `$(opendes-elastic-endpoint)`     |
| IDENTITY_CLIENT_ID                            | `$(identity_id)`                  |
| INTEGRATION_TESTER                            | `$(app-dev-sp-username)`          |
| MY_TENANT                                     | `opendes`                         |
| STORAGE_ACCOUNT                               | `$(opendes-storage)`              |
| STORAGE_ACCOUNT_KEY                           | `$(opendes-storage-key)`          |


```bash
DATA_PARTITION_NAME=opendes
DNS_HOST="<your_ingress_hostname>"  # ie: osdu.contoso.com

az pipelines variable-group create \
  --name "Azure Target Env - ${UNIQUE}" \
  --authorize true \
  --variables \
  AZURE_AD_APP_RESOURCE_ID='$(aad-client-id)' \
  AZURE_DEPLOY_SUBSCRIPTION='$(subscription-id)' \
  AZURE_LEGAL_SERVICEBUS='$('${DATA_PARTITION_NAME}'-sb-connection)' \
  AZURE_TENANT_ID='$(tenant-id)' \
  AZURE_TESTER_SERVICEPRINCIPAL_SECRET='$(app-dev-sp-password)' \
  CONTAINER_REGISTRY_NAME='$(container_registry)' \
  DNS_HOST="$DNS_HOST" \
  DOMAIN="contoso.com" \
  ELASTIC_ENDPOINT='$('${DATA_PARTITION_NAME}'-elastic-endpoint)' \
  IDENTITY_CLIENT_ID='$(identity_id)' \
  INTEGRATION_TESTER='$(app-dev-sp-username)' \
  MY_TENANT="$DATA_PARTITION_NAME" \
  STORAGE_ACCOUNT='$('${DATA_PARTITION_NAME}'-storage)' \
  STORAGE_ACCOUNT_KEY='$('${DATA_PARTITION_NAME}'-storage-key)' \
  -ojson
```

__Setup and Configure the ADO Library `Azure Target Env Secrets - demo`__

This variable group is a linked variable group that links to the Environment Key Vault and retrieves secret common settings.

- aad-client-id
- app-dev-sp-id
- app-dev-sp-password
- app-dev-sp-tenant-id
- app-dev-sp-username
- appinsights-key
- base-name-cr
- base-name-sr
- container-registry
- {partition-name}-cosmos-connection
- {partition-name}-cosmos-endpoint
- {partition-name}-cosmos-primary-key
- {partition-name}-elastic-endpoint
- {partition-name}-elastic-password
- {partition-name}-elastic-username
- osdu-identity-id
- subscription-id
- tenant-id


__Setup and Configure the ADO Library `Azure Service Release - partition`__

This variable group is the service specific variables necessary for testing and deploying the `partition` service.

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH     | `drop/provider/partition-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DPARTITION_BASE_URL=$(HOST_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DENVIRONMENT=HOSTED` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/partition-test-azure/pom.xml` |
| SERVICE_RESOURCE_NAME | `$(AZURE_PARTITION_SERVICE_NAME)` |


```bash
az pipelines variable-group create \
  --name "Azure Service Release - partition" \
  --authorize true \
  --variables \
  MAVEN_DEPLOY_POM_FILE_PATH="drop/provider/partition-azure" \
  MAVEN_INTEGRATION_TEST_OPTIONS='-DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DPARTITION_BASE_URL=$(HOST_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DENVIRONMENT=HOSTED' \
  MAVEN_INTEGRATION_TEST_POM_FILE_PATH="drop/deploy/testing/partition-test-azure/pom.xml" \
  SERVICE_RESOURCE_NAME='$(AZURE_PARTITION_SERVICE_NAME)' \
  -ojson
```

__Setup and Configure the ADO Library `Azure Service Release - entitlements-azure`__

This variable group is the service specific variables necessary for testing and deploying the `entitlements-azure` service.

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH     | `drop` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DENTITLEMENT_MEMBER_NAME_VALID=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DAZURE_AD_OTHER_APP_RESOURCE_OID=$(AZURE_AD_OTHER_APP_RESOURCE_OID) -DDOMAIN=$(DOMAIN) -DEXPIRED_TOKEN=$(EXPIRED_TOKEN) -DENTITLEMENT_GROUP_NAME_VALID=integ.test.data.creator -DENTITLEMENT_MEMBER_NAME_INVALID=InvalidTestAdmin -DAZURE_AD_USER_EMAIL=$(ad-user-email) -DAZURE_AD_USER_OID=$(ad-user-oid) -DAZURE_AD_GUEST_EMAIL=$(ad-guest-email) -DAZURE_AD_GUEST_OID=$(ad-guest-oid)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/integration-tests` |
| SERVICE_RESOURCE_NAME | `$(AZURE_ENTITLEMENTS_SERVICE_NAME)` |

```bash
az pipelines variable-group create \
  --name "Azure Service Release - entitlements-azure" \
  --authorize true \
  --variables \
  MAVEN_DEPLOY_POM_FILE_PATH="drop" \
  MAVEN_INTEGRATION_TEST_OPTIONS='-DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DENTITLEMENT_MEMBER_NAME_VALID=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DAZURE_AD_OTHER_APP_RESOURCE_OID=$(AZURE_AD_OTHER_APP_RESOURCE_OID) -DDOMAIN=$(DOMAIN) -DEXPIRED_TOKEN=$(EXPIRED_TOKEN) -DENTITLEMENT_GROUP_NAME_VALID=integ.test.data.creator -DENTITLEMENT_MEMBER_NAME_INVALID=InvalidTestAdmin -DAZURE_AD_USER_EMAIL=$(ad-user-email) -DAZURE_AD_USER_OID=$(ad-user-oid) -DAZURE_AD_GUEST_EMAIL=$(ad-guest-email) -DAZURE_AD_GUEST_OID=$(ad-guest-oid)' \
  MAVEN_INTEGRATION_TEST_POM_FILE_PATH="drop/deploy/integration-tests" \
  SERVICE_RESOURCE_NAME='$(AZURE_ENTITLEMENTS_SERVICE_NAME)' \
  -ojson
```

__Setup and Configure the ADO Library `Azure Service Release - legal`__

This variable group is the service specific variables necessary for testing and deploying the `legal` service.

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/legal-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DHOST_URL=$(LEGAL_URL) -DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_LEGAL_STORAGE_ACCOUNT=$(STORAGE_ACCOUNT) -DAZURE_LEGAL_STORAGE_KEY=$(STORAGE_ACCOUNT_KEY) -DAZURE_LEGAL_SERVICEBUS=$(AZURE_LEGAL_SERVICEBUS) -DAZURE_LEGAL_TOPICNAME=$(AZURE_LEGAL_TOPICNAME)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/legal-test-azure/pom.xml` |
| SERVICE_RESOURCE_NAME | `$(AZURE_LEGAL_SERVICE_NAME)` |

```bash
az pipelines variable-group create \
  --name "Azure Service Release - legal" \
  --authorize true \
  --variables \
  MAVEN_DEPLOY_POM_FILE_PATH="drop/provider/legal-azure" \
  MAVEN_INTEGRATION_TEST_OPTIONS='-DHOST_URL=$(LEGAL_URL) -DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_LEGAL_STORAGE_ACCOUNT=$(STORAGE_ACCOUNT) -DAZURE_LEGAL_STORAGE_KEY=$(STORAGE_ACCOUNT_KEY) -DAZURE_LEGAL_SERVICEBUS=$(AZURE_LEGAL_SERVICEBUS) -DAZURE_LEGAL_TOPICNAME=$(AZURE_LEGAL_TOPICNAME)' \
  MAVEN_INTEGRATION_TEST_POM_FILE_PATH="drop/deploy/testing/legal-test-azure/pom.xml" \
  SERVICE_RESOURCE_NAME='$(AZURE_LEGAL_SERVICE_NAME)' \
  -ojson
```


__Setup and Configure the ADO Library `Azure Service Release - storage`__

This variable group is the service specific variables necessary for testing and deploying the `storage` service.

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/storage-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DSTORAGE_URL=$(STORAGE_URL) -DLEGAL_URL=$(LEGAL_URL) -DTENANT_NAME=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DTESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_STORAGE_ACCOUNT=$(STORAGE_ACCOUNT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DDOMAIN=$(DOMAIN) -DPUBSUB_TOKEN=$(PUBSUB_TOKEN) -DDEPLOY_ENV=$(DEPLOY_ENV)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/storage-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_STORAGE_SERVICE_NAME)` |

```bash
az pipelines variable-group create \
  --name "Azure Service Release - storage" \
  --authorize true \
  --variables \
  MAVEN_DEPLOY_POM_FILE_PATH="drop/provider/storage-azure" \
  MAVEN_INTEGRATION_TEST_OPTIONS='-DSTORAGE_URL=$(STORAGE_URL) -DLEGAL_URL=$(LEGAL_URL) -DTENANT_NAME=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DTESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_STORAGE_ACCOUNT=$(STORAGE_ACCOUNT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DDOMAIN=$(DOMAIN) -DPUBSUB_TOKEN=$(PUBSUB_TOKEN) -DDEPLOY_ENV=$(DEPLOY_ENV)' \
  MAVEN_INTEGRATION_TEST_POM_FILE_PATH="drop/deploy/testing/storage-test-azure" \
  SERVICE_RESOURCE_NAME='$(AZURE_STORAGE_SERVICE_NAME)' \
  -ojson
```


__Setup and Configure the ADO Library `Azure Service Release - indexer-service`__

This variable group is the service specific variables necessary for testing and deploying the `indexer-service` service.

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/indexer-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -Daad_client_id=$(AZURE_AD_APP_RESOURCE_ID) -DSTORAGE_HOST=$(STORAGE_URL) -DELASTIC_HOST=$(ELASTIC_HOST) -DELASTIC_PORT=$(ELASTIC_PORT) -DELASTIC_USER_NAME=$(ELASTIC_USERNAME) -DELASTIC_PASSWORD=$(ELASTIC_PASSWORD) -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DENTITLEMENTS_DOMAIN=contoso.com -DENVIRONMENT=CLOUD -DLEGAL_TAG=opendes-public-usa-dataset-7643990 -DOTHER_RELEVANT_DATA_COUNTRIES=US` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/indexer-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_INDEXER_SERVICE_NAME)` |

```bash
az pipelines variable-group create \
  --name "Azure Service Release - indexer-service" \
  --authorize true \
  --variables \
  MAVEN_DEPLOY_POM_FILE_PATH="drop/provider/indexer-azure" \
  MAVEN_INTEGRATION_TEST_OPTIONS='-DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -Daad_client_id=$(AZURE_AD_APP_RESOURCE_ID) -DSTORAGE_HOST=$(STORAGE_URL) -DELASTIC_HOST=$(ELASTIC_HOST) -DELASTIC_PORT=$(ELASTIC_PORT) -DELASTIC_USER_NAME=$(ELASTIC_USERNAME) -DELASTIC_PASSWORD=$(ELASTIC_PASSWORD) -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DENTITLEMENTS_DOMAIN=contoso.com -DENVIRONMENT=CLOUD -DLEGAL_TAG=opendes-public-usa-dataset-7643990 -DOTHER_RELEVANT_DATA_COUNTRIES=US' \
  MAVEN_INTEGRATION_TEST_POM_FILE_PATH="drop/deploy/testing/indexer-test-azure" \
  SERVICE_RESOURCE_NAME='$(AZURE_INDEXER_SERVICE_NAME)' \
  -ojson
```



__Setup and Configure the ADO Library `Azure Service Release - search-service`__

This variable group is the service specific variables necessary for testing and deploying the `indexer-service` service.

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/search-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DSEARCH_HOST=$(SEARCH_URL) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DINDEXER_HOST=$() -DSTORAGE_HOST=$() -DELASTIC_HOST=$(ELASTIC_HOST) -DELASTIC_PORT=$(ELASTIC_PORT) -DELASTIC_USER_NAME=$(ELASTIC_USERNAME) -DELASTIC_PASSWORD=$(ELASTIC_PASSWORD) -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DENTITLEMENTS_DOMAIN=$(DOMAIN)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/integration-tests/search-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_SEARCH_SERVICE_NAME)` |

```bash
az pipelines variable-group create \
  --name "Azure Service Release - search-service" \
  --authorize true \
  --variables \
  MAVEN_DEPLOY_POM_FILE_PATH="drop/provider/search-azure" \
  MAVEN_INTEGRATION_TEST_OPTIONS='-DSEARCH_HOST=$(SEARCH_URL) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DINDEXER_HOST=$() -DSTORAGE_HOST=$() -DELASTIC_HOST=$(ELASTIC_HOST) -DELASTIC_PORT=$(ELASTIC_PORT) -DELASTIC_USER_NAME=$(ELASTIC_USERNAME) -DELASTIC_PASSWORD=$(ELASTIC_PASSWORD) -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DENTITLEMENTS_DOMAIN=$(DOMAIN)' \
  MAVEN_INTEGRATION_TEST_POM_FILE_PATH="drop/deploy/testing/integration-tests/search-test-azure" \
  SERVICE_RESOURCE_NAME='$(AZURE_SEARCH_SERVICE_NAME)' \
  -ojson
```


__Create the Chart Pipelines__

Create the pipelines and run things in this exact order.

1. Add a Pipeline for __chart-osdu-common__ to deploy common components.

    _Repo:_ `infra-azure-provisioning`
    _Path:_ `/charts/osdu-common/pipeline.yml`
    _Validate:_ https://<your_dns_name> is alive.

```bash
az pipelines create \
  --name 'chart-osdu-common'  \
  --repository infra-azure-provisioning  \
  --branch master  \
  --repository-type tfsgit  \
  --yaml-path /charts/osdu-common/pipeline.yml  \
  -ojson
```

2. Add a Pipeline for __chart-osdu-istio__  to deploy Istio components.

    _Repo:_ `infra-azure-provisioning`

    _Path:_ `/charts/osdu-istio/pipeline.yml`

    _Validate:_ Pods are running in Istio Namespace.


3. Add a Pipeline for __chart-osdu-istio-auth__  to deploy Istio Authorization Policies.

    _Repo:_ `infra-azure-provisioning`

    _Path:_ `/charts/osdu-istio-auth/pipeline.yml`

    _Validate:_ Authorization Policies exist in osdu namespace.


__Create the Service Pipelines__

Create the pipelines and run things in this exact order.

1. Add a Pipeline for __service-partition__  to deploy the Partition Service.

    _Repo:_ `partition`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/partition/v1/swagger-ui.html is alive.


2. Add a Pipeline for __service-entitlements-azure__  to deploy the Entitlements Service.
    > This pipeline may have to be run twice for integration tests to pass due to a preload data issue.

    _Repo:_ `entitlements-azure`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/entitlements/v1/swagger-ui.html is alive.


3. Add a Pipeline for __service-legal__  to deploy the Legal Service.

    _Repo:_ `legal`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/legal/v1/swagger-ui.html is alive.


4. Add a Pipeline for __service-storage__  to deploy the Storage Service.

    _Repo:_ `storage`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/storage/v2/swagger-ui.html is alive.


5. Add a Pipeline for __service-indexer-queue__  to deploy the Indexer Queue Function.

    _Repo:_ `indexer-queue`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ ScaledObject exist in osdu namespace.


6. Add a Pipeline for __service-indexer__  to deploy the Indexer Service.

    _Repo:_ `indexer-service`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/indexer/v2/swagger-ui.html is alive.


7. Add a Pipeline for __service-search__  to deploy the Search Service.

    _Repo:_ `search-service`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/search/v2/swagger-ui.html is alive.
