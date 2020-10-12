# Configure Continous Deployment for Infrastructure and Services into Environments.


## Setup Mirroring of Gitlab Repositories

> This typically takes about 30 minutes to complete.

__Create Empty Repositories__

Empty repositories need to be created that will be used by a pipeline to mirror gitlab repositories into.

| Repository Name           | Gitlab Location
|---------------------------|---------------------------|
| infra-azure-provisioning  | https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning.git |
| partition                 | https://community.opengroup.org/osdu/platform/system/partition.git |
| entitlements-azure        | https://community.opengroup.org/osdu/platform/security-and-compliance/entitlements-azure.git |
| legal                     | https://community.opengroup.org/osdu/platform/security-and-compliance/legal.git |
| indexer-queue             | https://community.opengroup.org/osdu/platform/system/indexer-queue.git |
| storage                   | https://community.opengroup.org/osdu/platform/system/storage.git |
| indexer-service           | https://community.opengroup.org/osdu/platform/system/indexer-service.git |
| search-service            | https://community.opengroup.org/osdu/platform/system/search-service.git |
| delivery                  | https://community.opengroup.org/osdu/platform/system/delivery.git       |

```bash
export ADO_ORGANIZATION=<organization_name>   # ie: osdu-demo
export ADO_PROJECT=<project_name>             # ie: osdu-mvp

# Create required ADO Repositories
for SERVICE in infra-azure-provisioning partition entitlements-azure legal storage indexer-queue indexer-service search-service delivery;
do
  az repos create --name $SERVICE --organization https://dev.azure.com/${ADO_ORGANIZATION} --project $ADO_PROJECT -ojson
done
```


__Create Variable Group__

A variable group will be used to hold the values of the GitLab Location to be mirrored.  Additionally a Personal Access Token is necessary to allow for git checkin.

Variable Group Name:  `Mirror Variables`

| Variable | Value |
|----------|-------|
| OSDU_INFRASTRUCTURE | https://dev.azure.com/osdu-demo/osdu/_git/osdu-infrastructure |
| INFRA_PROVISIONING_REPO | https://dev.azure.com/osdu-demo/osdu/_git/infra-azure-provisioning |
| PARTITION_REPO | https://dev.azure.com/osdu-demo/osdu/_git/partition |
| ENTITLEMENTS_REPO | https://dev.azure.com/osdu-demo/osdu/_git/entitlements-azure |
| LEGAL_REPO | https://dev.azure.com/osdu-demo/osdu/_git/legal |
| STORAGE_REPO | https://dev.azure.com/osdu-demo/osdu/_git/storage |
| INDEXER_QUEUE_REPO | https://dev.azure.com/osdu-demo/osdu/_git/indexer-queue |
| INDEXER_REPO | https://dev.azure.com/osdu-demo/osdu/_git/indexer-service |
| SEARCH_REPO | https://dev.azure.com/osdu-demo/osdu/_git/search-service |
| DELIVERY_REPO | https://dev.azure.com/osdu-demo/osdu/_git/delivery |
| ACCESS_TOKEN | <your_personal_access_token> |


```bash
az pipelines variable-group create \
  --name "Mirror Variables" \
  --authorize true \
  --organization https://dev.azure.com/${ADO_ORGANIZATION} \
  --project $ADO_PROJECT \
  --variables \
  INFRA_PROVISIONING_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/infra-azure-provisioning \
  PARTITION_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/partition \
  ENTITLEMENTS_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/entitlements-azure \
  LEGAL_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/legal \
  STORAGE_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/storage \
  INDEXER_QUEUE_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/indexer-queue \
  INDEXER_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/indexer-service \
  SEARCH_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/search-service \
  DELIVERY_REPO=https://dev.azure.com/${ADO_ORGANIZATION}/$ADO_PROJECT/_git/delivery \
  -ojson
```

Manually create a Personal Access Token following the [documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=preview-page) and add a Variable called `ACCESS_TOKEN` with the value being the PAT created.


__Create Pipeline__

Manually Create a Pipeline [`gitlab-sync`](../devops/gitlab-sync.yml)

```yaml
#  Copyright © Microsoft Corporation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


### UNCOMMENT IF YOU WANT A SCHEDULED PULL ####

# schedules:
#   - cron: "*/10 * * * *"
#     displayName: Hourly Pull Schedule
#     branches:
#       include:
#       - master
#     always: true

variables:
  - group: 'Mirror Variables'

jobs:
  - job: mirror_sync
    displayName: 'Pull Repositories'
    steps:

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'infra-azure-provisioning'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning.git'
        destinationGitRepositoryUri: '$(INFRA_PROVISIONING_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'partition'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/system/partition.git'
        destinationGitRepositoryUri: '$(PARTITION_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'entitlements-azure'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/security-and-compliance/entitlements-azure.git'
        destinationGitRepositoryUri: '$(ENTITLEMENTS_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'legal'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/security-and-compliance/legal.git'
        destinationGitRepositoryUri: '$(LEGAL_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'indexer-queue'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/system/indexer-queue.git'
        destinationGitRepositoryUri: '$(INDEXER_QUEUE_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'storage'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/system/storage.git'
        destinationGitRepositoryUri: '$(STORAGE_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'indexer-service'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/system/indexer-service.git'
        destinationGitRepositoryUri: '$(INDEXER_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'search-service'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/system/search-service.git'
        destinationGitRepositoryUri: '$(SEARCH_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'delivery'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/system/delivery.git'
        destinationGitRepositoryUri: '$(DELIVERY_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)
```

Execute the Pipeline which will then `git clone --mirror` the repositories into ADO.

```bash
az pipelines run --name gitlab-sync --organization https://dev.azure.com/${ADO_ORGANIZATION} --project $ADO_PROJECT -ojson
```


## Build Azure Resources

> This typically takes about 2 hours to complete.

__Configure Azure DevOps Service Connection__

- Configure an [ARM Resources Service Connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops) for the desired subscription.
  - Scope should be to the desired Subscription but do not apply scope to a Resource Group

```bash
SERVICE_CONNECTION_NAME=osdu-mvp-connection
export AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$ARM_CLIENT_SECRET

az devops service-endpoint azurerm create \
  --name $SERVICE_CONNECTION_NAME \
  --azure-rm-tenant-id $ARM_TENANT_ID \
  --azure-rm-subscription-id $ARM_SUBSCRIPTION_ID \
  --azure-rm-subscription-name $(az account show --subscription $ARM_SUBSCRIPTION_ID --query name -otsv) \
  --azure-rm-service-principal-id $ARM_CLIENT_ID \
  --organization https://dev.azure.com/${ADO_ORGANIZATION} \
  --project $ADO_PROJECT \
  -ojsonc
```


__Setup and Configure the ADO Library `Infrastructure Pipeline Variables`__

  | Variable | Value |
  |----------|-------|
  | AGENT_POOL | Hosted Ubuntu 1604 |
  | BUILD_ARTIFACT_NAME | infra-templates |
  | SERVICE_CONNECTION_NAME | <your_service_connection_name> |
  | TF_VAR_elasticsearch_secrets_keyvault_name | osducommon<your_unique>-kv |
  | TF_VAR_elasticsearch_secrets_keyvault_resource_group | osdu-common-<your_unique> |
  | TF_VAR_remote_state_account | osducommon<your_unique> |
  | TF_VAR_remote_state_container | remote-state-container |

```bash
SERVICE_CONNECTION_NAME=osdu-mvp-connection

az pipelines variable-group create \
  --name "Infrastructure Pipeline Variables" \
  --authorize true \
  --organization https://dev.azure.com/${ADO_ORGANIZATION} \
  --project $ADO_PROJECT \
  --variables \
  AGENT_POOL="Hosted Ubuntu 1604" \
  BUILD_ARTIFACT_NAME="infra-templates" \
  TF_VAR_elasticsearch_secrets_keyvault_name=$COMMON_VAULT  \
  TF_VAR_elasticsearch_secrets_keyvault_resource_group=osdu-common-${UNIQUE} \
  TF_VAR_remote_state_account=$TF_VAR_remote_state_account \
  TF_VAR_remote_state_container="remote-state-container" \
  SERVICE_CONNECTION_NAME=$SERVICE_CONNECTION_NAME \
  -ojson
```


__Setup and Configure the ADO Library `Infrastructure Pipeline Variables - demo`__

> You can specify the desired region locations you wish.


  | Variable | Value |
  |----------|-------|
  | ARM_SUBSCRIPTION_ID | <your_subscription_id> |
  | TF_VAR_aks_agent_vm_count | 3 |
  | TF_VAR_central_resources_workspace_name | cr-demo |
  | TF_VAR_cosmosdb_replica_location | eastus2 |
  | TF_VAR_data_partition_name | opendes |
  | TF_VAR_data_resources_workspace_name | dr-demo |
  | TF_VAR_elasticsearch_version | <your_elastic_version> |
  | TF_VAR_gitops_branch | master |
  | TF_VAR_gitops_path | providers/azure/hld-registry |
  | TF_VAR_gitops_ssh_url | git@<your_flux_repo> |
  | TF_VAR_principal_appId | <your_principal_appId> |
  | TF_VAR_principal_name | <your_principal_name> |
  | TF_VAR_principal_objectId | <your_principal_objectId> |
  | TF_VAR_principal_password | <your_principal_password> |
  | TF_VAR_resource_group_location | centralus |

```bash
ENVIRONMENT="demo"
REGION="centralus"
REGION_PAIR="eastus2"
PARTITION_NAME="opendes"
ELASTIC_VERSION="6.8.12"
GIT_REPO=git@ssh.dev.azure.com:v3/${ADO_ORGANIZATION}/${ADO_PROJECT}/k8-gitops-manifests

az pipelines variable-group create \
  --name "Infrastructure Pipeline Variables - ${ENVIRONMENT}" \
  --authorize true \
  --organization https://dev.azure.com/${ADO_ORGANIZATION} \
  --project $ADO_PROJECT \
  --variables \
  ARM_SUBSCRIPTION_ID="${ARM_SUBSCRIPTION_ID}" \
  TF_VAR_aks_agent_vm_count=3 \
  TF_VAR_central_resources_workspace_name="cr-${ENVIRONMENT}" \
  TF_VAR_cosmosdb_replica_location="${REGION_PAIR}" \
  TF_VAR_data_partition_name="${PARTITION_NAME}" \
  TF_VAR_data_resources_workspace_name="dr-${ENVIRONMENT}" \
  TF_VAR_elasticsearch_version="${ELASTIC_VERSION}" \
  TF_VAR_gitops_branch="master" \
  TF_VAR_gitops_path="providers/azure/hld-registry" \
  TF_VAR_gitops_ssh_url="${GIT_REPO}" \
  TF_VAR_principal_appId="${TF_VAR_principal_appId}" \
  TF_VAR_principal_name="${TF_VAR_principal_name}" \
  TF_VAR_principal_objectId="${TF_VAR_principal_objectId}" \
  TF_VAR_principal_password="${TF_VAR_principal_password}" \
  TF_VAR_resource_group_location="${REGION}" \
  -ojson
```

__Setup and Configure the ADO Library `Infrastructure Pipeline Secrets - demo`__
> This should be linked Secrets from Azure Key Vault `osducommon<your_unique>-kv`

  | Variable | Value |
  |----------|-------|
  | elastic-endpoint-dp1-demo | `*********` |
  | elastic-username-dp1-demo | `*********` |
  | elastic-password-dp1-demo | `*********` |


__Setup 2 Secure Files__

[Upload the 2 Secure files](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/secure-files?view=azure-devops).


  - azure-aks-gitops-ssh-key
  - azure-aks-node-ssh-key.pub



__Execute the pipelines in `osdu-infrastructure`__
> This should be executed to completion in order

1. `azure-pipeline-central.yml`
2. `azure-pipeline-data.yml`
3. `azure-pipeline-service.yml`

```bash
# Create and Deploy the Central Resources
az pipelines create \
  --name 'infrastructure-central-resources'  \
  --repository infra-azure-provisioning  \
  --branch master  \
  --repository-type tfsgit  \
  --yaml-path /infra/templates/osdu-r3-mvp/pipeline-central-resources.yml  \
  --organization https://dev.azure.com/${ADO_ORGANIZATION}  \
  --project $ADO_PROJECT  \
  -ojson


```

## Deploy OSDU Services

> This typically takes about 3-4 hours to complete.


__Setup and Configure the ADO Library `Azure - OSDU`__

| Variable                                      | Value |
|-----------------------------------------------|-------|
| ADMIN_EMAIL                                   | <your_sslcert_admin_email>                |
| AGENT_POOL                                    | `Hosted Ubuntu 1604`                      |
| AZURE_AD_GUEST_EMAIL                          | `$(ad-guest-email)`                       |
| AZURE_AD_GUEST_OID                            | `$(ad-guest-oid)`                         |
| AZURE_AD_OTHER_APP_RESOURCE_ID                | `$(osdu-infra-<your_unique>-test-app-noaccess-id)` |
| AZURE_AD_OTHER_APP_RESOURCE_OID               | `$(osdu-infra-<your_unique>-test-noaccess-app-oid)`|
| AZURE_AD_USER_EMAIL                           | `$(ad-user-email)`                        |
| AZURE_AD_USER_OID                             | `$(ad-user-oid)`                          |
| AZURE_LEGAL_TOPICNAME                         | `legaltags`                               |
| DEPLOY_ENV                                    | `empty`                                   |
| ENTITLEMENT_URL                               | `https://$(DNS_HOST)/entitlements/v1/`    |
| EXPIRED_TOKEN                                 | <an_expired_token>                        |
| HOST_URL                                      | `https://$(DNS_HOST)/`                    |
| LEGAL_URL                                     | `https://$(DNS_HOST)/api/legal/v1/`       |
| NO_DATA_ACCESS_TESTER                         | `$(osdu-infra-azg-test-app-noaccess-id)`  |
| NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET | `$(osdu-infra-azg-test-app-noaccess-key)` |
| PUBSUB_TOKEN                                  | `empty`                                   |
| SERVICE_CONNECTION_NAME                       | <your_service_connection_name>            |
| GOOGLE_CLOUD_PROJECT                          | `opendes`                                 |



__Setup and Configure the ADO Library `Azure - OSDU Secrets`__

> This Library is linked to the Common Key Vault

- osdu-infra-{unique}-test-app-id
- osdu-infra-{unique}-test-app-key
- osdu-infra-{unique}-test-app-noaccess-id
- osdu-infra-{unique}-test-app-noaccess-oid
- ad-guest-email
- ad-guest-oid
- ad-user-email
- ad-user-oid
- istio-username
- istio-password



__Setup and Configure the ADO Library `Azure Target Env - demo`__

> This library is subject to change due to pipeline tranformation work not completed.

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


__Setup and Configure the ADO Library `Azure Target Env Secrets - demo`__

> This Library is linked to the Enviroment Key Vault

- aad-client-id
- app-dev-sp-id
- app-dev-sp-password
- app-dev-sp-tenant-id
- app-dev-sp-username
- appinsights-key
- base-name-cr
- base-name-sr
- container-registry
- opendes-cosmos-connection
- opendes-cosmos-endpoint
- opendes-cosmos-primary-key
- opendes-elastic-endpoint
- opendes-elastic-password
- opendes-elastic-username
- osdu-identity-id
- subscription-id
- tenant-id


__Setup and Configure the ADO Library `Azure Service Release - partition`__

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH     | `drop/provider/partition-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DPARTITION_BASE_URL=$(HOST_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DENVIRONMENT=HOSTED` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/partition-test-azure/pom.xml` |
| SERVICE_RESOURCE_NAME | `$(AZURE_PARTITION_SERVICE_NAME)` |


__Setup and Configure the ADO Library `Azure Service Release - entitlements-azure`__

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH     | `drop` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DENTITLEMENT_MEMBER_NAME_VALID=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DAZURE_AD_OTHER_APP_RESOURCE_OID=$(AZURE_AD_OTHER_APP_RESOURCE_OID) -DDOMAIN=$(DOMAIN) -DEXPIRED_TOKEN=$(EXPIRED_TOKEN) -DENTITLEMENT_GROUP_NAME_VALID=integ.test.data.creator -DENTITLEMENT_MEMBER_NAME_INVALID=InvalidTestAdmin -DAZURE_AD_USER_EMAIL=$(ad-user-email) -DAZURE_AD_USER_OID=$(ad-user-oid) -DAZURE_AD_GUEST_EMAIL=$(ad-guest-email) -DAZURE_AD_GUEST_OID=$(ad-guest-oid)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/integration-tests` |
| SERVICE_RESOURCE_NAME | `$(AZURE_ENTITLEMENTS_SERVICE_NAME)` |


__Setup and Configure the ADO Library `Azure Service Release - legal`__

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/legal-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DHOST_URL=$(LEGAL_URL) -DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_LEGAL_STORAGE_ACCOUNT=$(STORAGE_ACCOUNT) -DAZURE_LEGAL_STORAGE_KEY=$(STORAGE_ACCOUNT_KEY) -DAZURE_LEGAL_SERVICEBUS=$(AZURE_LEGAL_SERVICEBUS) -DAZURE_LEGAL_TOPICNAME=$(AZURE_LEGAL_TOPICNAME)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/legal-test-azure/pom.xml` |
| SERVICE_RESOURCE_NAME | `$(AZURE_LEGAL_SERVICE_NAME)` |


__Setup and Configure the ADO Library `Azure Service Release - storage`__

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/storage-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DSTORAGE_URL=$(STORAGE_URL) -DLEGAL_URL=$(LEGAL_URL) -DTENANT_NAME=$(MY_TENANT) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DTESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_STORAGE_ACCOUNT=$(STORAGE_ACCOUNT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DDOMAIN=$(DOMAIN) -DPUBSUB_TOKEN=$(PUBSUB_TOKEN) -DDEPLOY_ENV=$(DEPLOY_ENV)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/storage-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_STORAGE_SERVICE_NAME)` |


__Setup and Configure the ADO Library `Azure Service Release - indexer-service`__

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/indexer-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -Daad_client_id=$(AZURE_AD_APP_RESOURCE_ID) -DSTORAGE_HOST=$(STORAGE_URL) -DELASTIC_HOST=$(ELASTIC_HOST) -DELASTIC_PORT=$(ELASTIC_PORT) -DELASTIC_USER_NAME=$(ELASTIC_USERNAME) -DELASTIC_PASSWORD=$(ELASTIC_PASSWORD) -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DENTITLEMENTS_DOMAIN=contoso.com -DENVIRONMENT=CLOUD -DLEGAL_TAG=opendes-public-usa-dataset-7643990 -DOTHER_RELEVANT_DATA_COUNTRIES=US` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/indexer-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_INDEXER_SERVICE_NAME)` |


__Setup and Configure the ADO Library `Azure Service Release - search-service`__

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/search-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DSEARCH_HOST=$(SEARCH_URL) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DINDEXER_HOST=$() -DSTORAGE_HOST=$() -DELASTIC_HOST=$(ELASTIC_HOST) -DELASTIC_PORT=$(ELASTIC_PORT) -DELASTIC_USER_NAME=$(ELASTIC_USERNAME) -DELASTIC_PASSWORD=$(ELASTIC_PASSWORD) -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DENTITLEMENTS_DOMAIN=$(DOMAIN)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/integration-tests/search-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_SEARCH_SERVICE_NAME)` |



__Load Storage Container Integration Test Data__

The data to be loaded before services are deployed and can be found in the osdu-infrastructure repository `osdu-infrastructure/docs/osdu/integration-test-data/`.

Container: `legal-service-azure-configuration`

- Legal_COO.json


__Load Cosmos DB Integration Test Data__

The data to be loaded before services are deployed and can be found in the osdu-infrastructure repository `osdu-infrastructure/docs/osdu/integration-test-data/` and has to be modified with environment specific information as necessary.

- tenant_info_1.json
- tenant_info_2.json
- user_info_1.json
- user_info_2.json
- legal_tag_1.json
- legal_tag_2.json
- legal_tag_3.json
- storage_schema_1.json
- storage_schema_2.json
- storage_schema_3.json
- storage_schema_4.json
- storage_schema_5.json
- storage_schema_6.json
- storage_schema_7.json
- storage_schema_8.json
- storage_schema_9.json
- storage_schema_10.json
- storage_schema_11.json


__Configure the ADO Charts and Service Pipelines__

Create the pipelines and run things in this exact order.


1. Add a Pipeline for __chart-osdu-common__ to deploy common components.
    > Ensure DNS is configured for your Gateway IP to DNS_HOST prior.

    _Repo:_ `infra-azure-provisioning`

    _Path:_ `/charts/osdu-common/pipeline.yml`

    _Validate:_ https://<your_dns_name> is alive.


2. Add a Pipeline for __chart-osdu-istio__  to deploy Istio components.

    _Repo:_ `infra-azure-provisioning`

    _Path:_ `/charts/osdu-istio/pipeline.yml`

    _Validate:_ Pods are running in Istio Namespace.


3. Add a Pipeline for __chart-osdu-istio-auth__  to deploy Istio Authorization Policies.

    _Repo:_ `infra-azure-provisioning`

    _Path:_ `/charts/osdu-istio-auth/pipeline.yml`

    _Validate:_ Authorization Policies exist in osdu namespace.


4. Add a Pipeline for __service-partition__  to deploy the Partition Service.

    _Repo:_ `partition`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/partition/v1/swagger-ui.html is alive.



5. Add a Pipeline for __service-entitlements-azure__  to deploy the Entitlements Service.
    > This pipeline may have to be run twice for integration tests to pass due to a preload data issue.

    _Repo:_ `entitlements-azure`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/entitlements/v1/swagger-ui.html is alive.


6. Add a Pipeline for __service-legal__  to deploy the Legal Service.

    _Repo:_ `legal`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/legal/v1/swagger-ui.html is alive.


6. Add a Pipeline for __service-storage__  to deploy the Storage Service.

    _Repo:_ `storage`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/storage/v2/swagger-ui.html is alive.


7. Add a Pipeline for __service-indexer-queue__  to deploy the Indexer Queue Function.

    _Repo:_ `indexer-queue`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ ScaledObject exist in osdu namespace.


8. Add a Pipeline for __service-indexer__  to deploy the Indexer Service.

    _Repo:_ `indexer-service`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/indexer/v2/swagger-ui.html is alive.


9. Add a Pipeline for __service-search__  to deploy the Search Service.

    _Repo:_ `search-service`

    _Path:_ `/devops/azure/pipeline.yml`

    _Validate:_ https://<your_dns_name>/api/search/v2/swagger-ui.html is alive.

