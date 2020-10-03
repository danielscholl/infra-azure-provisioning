# infra-azure-provisioning

Azure Infrastructure provisioning scripts and templates are hosted in a Github repository that is accessible here:
[Azure Infrastructure Templates](https://github.com/azure/osdu-infrastructure)

The repository contains the infrastructure as code implementation and pipelines necessary for the required infrastructure in Azure to host OSDU. We've chosen to host the infrastructure code in Github because the infrastructure code is very closely tied to Azure, requires a high degree of priviledges and access to our Azure instance and leverages capability inherent to Azure DevOps. Unfortunately this high level of integration could not be entirely accomodated out of Gitlab, and therefore led us to choose to host the code in Github.

The current approach to deploying OSDU into your own Azure tenant involves the following steps:

1- Follow the directions in the infrastructure repository to deploy the infrastructure:
- R3 MVP which includes latest from master and the most up-to-date master branch deployment.It can be found [here](https://github.com/Azure/osdu-infrastructure/blob/master/infra/templates/osdu-r3-mvp). There is a risk of using the latest if you don't want to deal with potential inconsistencies.

2- Deploy the services using a mirrored Azure Devops project (instructions in [here](https://github.com/azure/osdu-infrastructure))

3- Load the data

## Service Onboarding

### Enable Azure Tasks in the service pipeline

Each service has a common build pipeline `.gitlab-ci.yaml` and azure has to be added to the pipeline in order for the azure tasks to trigger

__Azure Provider Environment Variables__
Add the 3 required variables to the pipeline

- AZURE_SERVICE - This variable names the service  ie: `storage`
- AZURE_BUILD_SUBDIR - This variable is the path where the service azure provider pom file can be found ie: `provider/storage-azure`
- AZURE_TEST_SUBDIR - This variable is the path where the testing azure provider pom file can be found ie: `testing/storage-test-azure`

```yaml
variables:

  AZURE_SERVICE: <service_name>
  AZURE_BUILD_SUBDIR: provider/<azure_directory>
  AZURE_TEST_SUBDIR: testing/<azure_directory>
```

__Azure Provider CI/CD Template__
Add the azure ci/cd template include

```yaml

include:
  - project: "osdu/platform/ci-cd-pipelines"
    file: "cloud-providers/azure.yml"
```

### Disable for the Project Azure Integration Testing

The CI/CD Pipeline has a feature flag to disable Integration Testing for azure.  Set this variable to be true at the Project CI/CD Variable Settings.

```
AZURE_SKIP_TEST=true
```

### Create the Helm Chart and Pipelines for the Service

Each service is responsible to maintain the helm chart necessary to install the service.  Charts for services are typically very similar but unique variables exist in the deployment.yaml that would be different for each services, additionally some files have service specific names that have to be modified from service to service.

Each service is also responsible to maintain the pipeline files.  There are 2 pipeline files, one for MS development flows and the other for customer demo flows.

```
├── devops
│   ├── azure
│   │   ├── README.md
│   │   ├── chart
│   │   │   ├── Chart.yaml
│   │   │   ├── helm-config.yaml
│   │   │   ├── templates
│   │   │   │   ├── deployment.yaml
│   │   │   │   └── service.yaml
│   │   │   └── values.yaml
│   │   └── release.yaml
│   │   └── development-pipeline.yml
│   │   └── pipeline.yml
```

### Execute the pipeline

Execute the pipeline and the service should now build, deploy and start.  Validate that the service has started successfully.

### Update the Ingress Controller

If the service has a public ingress the service ingress needs to be updated which can be found in the osdu-common chart.

### Update the Developer Variables

Each service typically needs specific variables necessary to start the service and test the service.  These developer variables need to be updated so that other developers have the ability to work with the service locally.

### Validate Integration Tests

Using the Developer Variables the deployed service needs to be validated that all integration tests pass successfully and the required variables have been identified.

### Update the Azure Cloud Provider CI/CD Template and enable testing

Once the service can be integration tested successfully any additional variables necessary for testing need to be updated in the `cloud-providers/azure.yml` file.

Remove the `AZURE_SKIP_TESTS` variable at the project and execute the pipeline


## Configure Continous Deployment for Services into Environemts.

> This typically takes about 10-15 minutes to complete.

- Create a new ADO Project in your organization called `osdu`

- In the base project repo now import the base project
  - https://dev.azure.com/osdu-demo/osdu/_git/osdu

- Create Empty Repositories (No Readme)
  - osdu-infrastructure
  - infra-azure-provisioning
  - entitlements-azure
  - legal
  - indexer-queue
  - storage
  - indexer-service
  - search-service

- Setup a Variable Group `Mirror Variables` to mirror repositories

    | Variable | Value |
    |----------|-------|
    | ACCESS_TOKEN | <your_personal_access_token> |
    | OSDU_INFRASTRUCTURE | https://dev.azure.com/osdu-demo/osdu/_git/osdu-infrastructure |
    | INFRA_PROVISIONING_REPO | https://dev.azure.com/osdu-demo/osdu/_git/infra-azure-provisioning |
    | ENTITLEMENTS_REPO | https://dev.azure.com/osdu-demo/osdu/_git/entitlements-azure |
    | LEGAL_REPO | https://dev.azure.com/osdu-demo/osdu/_git/legal |
    | STORAGE_REPO | https://dev.azure.com/osdu-demo/osdu/_git/storage |
    | INDEXER_QUEUE_REPO | https://dev.azure.com/osdu-demo/osdu/_git/indexer-queue |
    | INDEXER_REPO | https://dev.azure.com/osdu-demo/osdu/_git/indexer-service |
    | SEARCH_REPO | https://dev.azure.com/osdu-demo/osdu/_git/search |

- Add a Pipeline __gitlab-sync__

```yaml
trigger:
  batch: true
  branches:
    include:
    - master
  paths:
    include:
    - /azure-pipeline.yml
    exclude:
    - /**/*.md

schedules:
  - cron: "*/10 * * * *"
    displayName: Hourly Pull Schedule
    branches:
      include:
      - master
    always: true

variables:
  - group: 'Mirror Variables'

jobs:
  - job: mirror_sync
    displayName: 'Pull Repositories'
    steps:

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

    - task: swellaby.mirror-git-repository.mirror-git-repository-vsts-task.mirror-git-repository-vsts-task@1
      displayName: 'infra-azure-provisioning'
      inputs:
        sourceGitRepositoryUri: 'https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning.git'
        destinationGitRepositoryUri: '$(INFRA_PROVISIONING_REPO)'
        destinationGitRepositoryPersonalAccessToken: $(ACCESS_TOKEN)

```

- Execute the Pipeline which will then pull the required code into the ADO project repos.


## Build osdu-infrastructure

> This typically takes about 2 hours to complete.

__Prerequisites__

Here is an Azure Virtual [Developer Machine](https://github.com/danielscholl/hol-win10) that can be used if necessary.

>Procedures are tested using Ubuntu within WSL for Windows 10.  _(Typically MacOS works well)_

__Clone Infrastructure__

Clone the osdu-infrastructure repository to a local machine.

__Execute Install Script__

The script ./scripts/install.sh will conveniently setup the common things that are necessary to execute a pipeline.

- Login to the azure cli and set the default account to the desired subscription.

- Follow the instructions for bootstraping the osdu-infrastructure pipeline located in the README.md of that project space.

### Installed Common Resources

1. Resource Group
2. Storage Account
3. Key Vault
4. Applications for Integration Testing (2)

__Elastic Search Setup__

Infrastructure assumes bring your own Elastic Search Instance at a version of `6.8.3` and access information must be stored in the Common KeyVault.

```bash
AZURE_VAULT="<your_keyvault>"
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-endpoint-ado-demo" --value <your_es_endpoint>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-username-ado-demo" --value <your_es_username>
az keyvault secret set --vault-name $AZURE_VAULT --name "elastic-password-ado-demo" --value <your_es_password>

# This command will extract all Key Vault Secrets
for i in `az keyvault secret list --vault-name $AZURE_VAULT --query [].id -otsv`
do
   echo "export ${i##*/}=\"$(az keyvault secret show --vault-name $AZURE_VAULT --id $i --query value -otsv)\""
done

```

### Configure Azure DevOps Service Connection

- Configure an [ARM Resources Service Connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops) for the desired subscription.
  - Scope should be to the desired Subscription but do not apply scope to a Resource Group

- Locate the Service Principal created (<organization-project-subscription>) in Azure Active Directory and elevate the principal capability by adding in 2 API Permissions
  - Azure Active Directory Graph - Application.ReadWrite.OwnedBy
  - Microsoft Graph - Application.ReadWrite.OwnedBy

> These 2 API's require `Grant Admin Consent`

- In Azure Portal locat the subscription and under Access control (IAM) add an Owner Role Assignment to the principal then remove the default created Contributor role.


### Setup ADO required Libraries

- Setup and Configure the ADO Library `Infrastructure Pipeline Variables`

  | Variable | Value |
  |----------|-------|
  | AGENT_POOL | Hosted Ubuntu 1604 |
  | BUILD_ARTIFACT_NAME | infra-templates` |
  | SERVICE_CONNECTION_NAME | <your_service_connection_name> |
  | TF_VAR_elasticsearch_secrets_keyvault_name | osducommon<your_unique>-kv |
  | TF_VAR_elasticsearch_secrets_keyvault_resource_group | osdu-common-<your_unique> |
  | TF_VAR_remote_state_account | osducommon<your_unique> |
  | TF_VAR_remote_state_container | remote-state-container |

- Setup and Configure the ADO Library `Infrastructure Pipeline Variables - demo`

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


> You can specify the desired region locations you wish.

- Setup and Configure the ADO Library `Infrastructure Pipeline Secrets - demo`

  | Variable | Value |
  |----------|-------|
  | elastic-endpoint-dp1-dev | `*********` |
  | elastic-username-dp1-dev | `*********` |
  | elastic-password-dp1-dev | `*********` |

> This should be linked Secrets from Azure Key Vault `osducommon<your_unique>-kv`

- Setup 2 Secure Files
  - azure-aks-gitops-ssh-key
  - azure-aks-node-ssh-key.pub

** This is future AKS work but required. Ensure the names of files uploaded have the exact names listed which will require renaming the .ssh key information created by the script.

- Execute the pipelines in __osdu-infrastructure__ in the following order
  - `azure-pipeline-central.yml`
  - `azure-pipeline-data.yml`
  - `azure-pipeline-service.yml`



## Deploy OSDU Services

> This typically takes about 3-4 hours to complete.

### Setup OSDU ADO Libraries

- Setup and Configure the ADO Library `Azure - OSDU`

| Variable                                      | Value |
|-----------------------------------------------|-------|
| ADMIN_EMAIL                                   | <your_sslcert_admin_email> |
| AGENT_POOL                                    | `Hosted Ubuntu 1604` |
| AZURE_AD_OTHER_APP_RESOURCE_ID                | `$(osdu-infra-<your_unique>-test-app-id)` |
| AZURE_AD_OTHER_APP_RESOURCE_OID               | `$(osdu-infra-<your_unique>-test-app-oid)` |
| AZURE_TENANT_ID                               | <your_ad_tenant_id> |
| elastic-endpoint                              | `$(opendes-elastic-endpoint)` |
| HOST_URL                                      | `https://$(DNS_HOST)/` |
| NO_DATA_ACCESS_TESTER                         | `$(osdu-infra-azg-test-app-noaccess-id)` |
| NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET | `$(osdu-infra-azg-test-app-noaccess-key)` |
| SERVICE_CONNECTION_NAME                       | <your_service_connection_name> |

- Setup and Configure the ADO Library `Azure - OSDU Secrets`
> This Library is linked to the Common Key Vault

- osdu-infra-{unique}-test-app-id
- osdu-infra-{unique}-test-app-key
- osdu-infra-{unique}-test-app-noaccess-id
- osdu-infra-{unique}-test-app-noaccess-key
- ad-guest-email
- ad-guest-oid
- ad-user-email
- ad-user-oid

### Setup Environment ADO Libraries

- Setup and Configure the ADO Library `Azure Target Env - demo`

| Variable | Value |
|----------|-------|
| AZURE_AD_APP_RESOURCE_ID                      | `$(aad-client-id)` |
| AZURE_DEPLOY_SUBSCRIPTION                     | <your_subscription_id> |
| AZURE_TESTER_SERVICEPRINCIPAL_SECRET          | `$(app-dev-sp-password)` |
| BASE_NAME_CR                                  |   _(ie:  osdu-mvp-crdemo-0knr)_   |
| BASE_NAME_SR                                  |   _(ie:  osdu-mvp-srdemo-wzjm)_   |
| CONTAINER_REGISTRY_NAME                       |   _(ie:  osdumvpcrdemo0knrcr)_   |
| DNS_HOST                                      | <your_FQDN> |
| IDENTITY_CLIENT_ID                            | <your_osdu_identity_client_id> |
| INTEGRATION_TESTER                            | `$(app-dev-sp-username)` |
| ISTIO_PASSWORD                                | <your_istio_ui_password> |
| ISTIO_USERNAME                                | <your_istio_ui_username> |
| MY_TENANT                                     | `opendes` |



- Setup and Configure the ADO Library `Azure Target Env Secrets - demo`
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


### Setup Service ADO Libraries

- __Setup and Configure the ADO Library__ `Azure Service Release - partition`

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_GOALS | `azure-webapp:deploy` |
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/partition-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DPARTITION_BASE_URL=$(HOST_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_TENANT_ID) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DENVIRONMENT=HOSTED` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/partition-test-azure/pom.xml` |
| SERVICE_RESOURCE_NAME | `$(AZURE_PARTITION_SERVICE_NAME)` |



- __Setup and Configure the ADO Library__ `Azure Service Release - entitlements`

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_GOALS | `azure-webapp:deploy` |
| MAVEN_DEPLOY_OPTIONS | `--settings $(System.DefaultWorkingDirectory)/drop/maven/settings.xml -DAZURE_DEPLOY_TENANT=$(AZURE_DEPLOY_TENANT) -DAZURE_DEPLOY_CLIENT_ID=$(AZURE_DEPLOY_CLIENT_ID) -DAZURE_DEPLOY_CLIENT_SECRET=$(AZURE_DEPLOY_CLIENT_SECRET) -Dazure.appservice.resourcegroup=$(AZURE_DEPLOY_RESOURCE_GROUP) -Dazure.appservice.plan=$(AZURE_DEPLOY_APPSERVICE_PLAN) -Dazure.appservice.appname=$(AZURE_ENTITLEMENTS_SERVICE_NAME) -Dazure.appservice.subscription=$(AZURE_DEPLOY_SUBSCRIPTION)` |
| MAVEN_DEPLOY_POM_FILE_PATH | `drop` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DDOMAIN=$(DOMAIN) -DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DENTITLEMENT_APP_KEY=$(entitlement-key) -DMY_TENANT=$(MY_TENANT) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_DEPLOY_TENANT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_AD_OTHER_APP_RESOURCE_ID=$(AZURE_AD_OTHER_APP_RESOURCE_ID) -DEXPIRED_TOKEN=$(EXPIRED_TOKEN)  -DENTITLEMENT_MEMBER_NAME_VALID=$(INTEGRATION_TESTER) -DENTITLEMENT_MEMBER_NAME_INVALID=InvalidTestAdmin -DENTITLEMENT_GROUP_NAME_VALID=integ.test.data.creator` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/integration-tests` |
| SERVICE_RESOURCE_NAME | `$(AZURE_ENTITLEMENTS_SERVICE_NAME)` |



- __Setup and Configure the ADO Library__ `Azure Service Release - legal`

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_GOALS | `azure-webapp:deploy` |
| MAVEN_DEPLOY_OPTIONS | `--settings $(System.DefaultWorkingDirectory)/drop/provider/legal-azure/maven/settings.xml -DAZURE_DEPLOY_TENANT=$(AZURE_DEPLOY_TENANT) -DAZURE_DEPLOY_CLIENT_ID=$(AZURE_DEPLOY_CLIENT_ID) -DAZURE_DEPLOY_CLIENT_SECRET=$(AZURE_DEPLOY_CLIENT_SECRET) -Dazure.appservice.resourcegroup=$(AZURE_DEPLOY_RESOURCE_GROUP) -Dazure.appservice.plan=$(AZURE_DEPLOY_APPSERVICE_PLAN) -Dazure.appservice.appname=$(AZURE_LEGAL_SERVICE_NAME) -Dazure.appservice.subscription=$(AZURE_DEPLOY_SUBSCRIPTION)` |
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/legal-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DHOST_URL=$(LEGAL_URL) -DENTITLEMENT_URL=$(ENTITLEMENT_URL) -DMY_TENANT=$(MY_TENANT) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_DEPLOY_TENANT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DAZURE_LEGAL_STORAGE_ACCOUNT=$(AZURE_STORAGE_ACCOUNT) -DAZURE_LEGAL_STORAGE_KEY=$(storage-account-key) -DAZURE_LEGAL_SERVICEBUS=$(AZURE_LEGAL_SERVICEBUS) -DAZURE_LEGAL_TOPICNAME=$(AZURE_LEGAL_TOPICNAME)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/legal-test-azure/pom.xml` |
| SERVICE_RESOURCE_NAME | `$(AZURE_LEGAL_SERVICE_NAME)` |



__- Setup and Configure the ADO Library__ `Azure Service Release - storage`

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_GOALS | `azure-webapp:deploy` |
| MAVEN_DEPLOY_OPTIONS | `--settings $(System.DefaultWorkingDirectory)/drop/provider/storage-azure/maven/settings.xml -DAZURE_DEPLOY_TENANT=$(AZURE_DEPLOY_TENANT) -DAZURE_DEPLOY_CLIENT_ID=$(AZURE_DEPLOY_CLIENT_ID) -DAZURE_DEPLOY_CLIENT_SECRET=$(AZURE_DEPLOY_CLIENT_SECRET) -Dazure.appservice.resourcegroup=$(AZURE_DEPLOY_RESOURCE_GROUP) -Dazure.appservice.plan=$(AZURE_DEPLOY_APPSERVICE_PLAN) -Dazure.appservice.appname=$(AZURE_STORAGE_SERVICE_NAME) -Dazure.appservice.subscription=$(AZURE_DEPLOY_SUBSCRIPTION)` |
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/storage-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DDOMAIN=$(DOMAIN) -DSTORAGE_URL=$(STORAGE_URL) -DLEGAL_URL=$(LEGAL_URL) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DNO_DATA_ACCESS_TESTER=$(NO_DATA_ACCESS_TESTER) -DTESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DNO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET=$(NO_DATA_ACCESS_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_DEPLOY_TENANT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DDEPLOY_ENV=$(DEPLOY_ENV) -DPUBSUB_TOKEN=$(PUBSUB_TOKEN) -DTENANT_NAME=$(MY_TENANT) -DAZURE_STORAGE_ACCOUNT=$(AZURE_STORAGE_ACCOUNT)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/storage-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_STORAGE_SERVICE_NAME)` |
`



__- Setup and Configure the ADO Library__ `Azure Service Release - indexer`

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_GOALS | `azure-webapp:deploy` |
| MAVEN_DEPLOY_OPTIONS | `--settings $(System.DefaultWorkingDirectory)/drop/provider/indexer-azure/maven/settings.xml -DAZURE_DEPLOY_TENANT=$(AZURE_DEPLOY_TENANT) -DAZURE_DEPLOY_CLIENT_ID=$(AZURE_DEPLOY_CLIENT_ID) -DAZURE_DEPLOY_CLIENT_SECRET=$(AZURE_DEPLOY_CLIENT_SECRET) -Dazure.appservice.resourcegroup=$(AZURE_DEPLOY_RESOURCE_GROUP) -Dazure.appservice.plan=$(AZURE_DEPLOY_APPSERVICE_PLAN) -Dazure.appservice.appname=$(AZURE_INDEXER_SERVICE_NAME) -Dazure.appservice.subscription=$(AZURE_DEPLOY_SUBSCRIPTION) -DELASTIC_USER_NAME=$(elastic-username) -DELASTIC_PASSWORD=$(elastic-password) -DELASTIC_HOST=$(elastic-host) -DELASTIC_PORT=$(elastic-port)` |
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/indexer-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DAZURE_AD_TENANT_ID=$(AZURE_DEPLOY_TENANT) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID) -DELASTIC_USER_NAME=$(elastic-username) -DELASTIC_PASSWORD=$(elastic-password) -DELASTIC_HOST=$(elastic-host) -DELASTIC_PORT=$(elastic-port)  -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DLEGAL_TAG=opendes-public-usa-dataset-7643990 -DOTHER_RELEVANT_DATA_COUNTRIES=US -DENTITLEMENTS_DOMAIN=contoso.com -DENVIRONMENT=CLOUD -DSTORAGE_HOST=$(STORAGE_URL)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/indexer-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_INDEXER_SERVICE_NAME)` |



__- Setup and Configure the ADO Library__ `Azure Service Release - search`

| Variable | Value |
|----------|-------|
| MAVEN_DEPLOY_GOALS | `azure-webapp:deploy` |
| MAVEN_DEPLOY_OPTIONS | `--settings $(System.DefaultWorkingDirectory)/drop/provider/search-azure/maven/settings.xml -DAZURE_DEPLOY_TENANT=$(AZURE_DEPLOY_TENANT) -DAZURE_DEPLOY_CLIENT_ID=$(AZURE_DEPLOY_CLIENT_ID) -DAZURE_DEPLOY_CLIENT_SECRET=$(AZURE_DEPLOY_CLIENT_SECRET) -Dazure.appservice.resourcegroup=$(AZURE_DEPLOY_RESOURCE_GROUP) -Dazure.appservice.plan=$(AZURE_DEPLOY_APPSERVICE_PLAN) -Dazure.appservice.appname=$(AZURE_SEARCH_SERVICE_NAME) -Dazure.appservice.subscription=$(AZURE_DEPLOY_SUBSCRIPTION)` |
| MAVEN_DEPLOY_POM_FILE_PATH | `drop/provider/search-azure` |
| MAVEN_INTEGRATION_TEST_OPTIONS | `-DOTHER_RELEVANT_DATA_COUNTRIES= -DINTEGRATION_TEST_AUDIENCE= -DDEFAULT_DATA_PARTITION_ID_TENANT1=$(MY_TENANT) -DDEFAULT_DATA_PARTITION_ID_TENANT2=othertenant2 -DELASTIC_USER_NAME=$(elastic-username) -DELASTIC_PASSWORD=$(elastic-password) -DELASTIC_HOST=$(elastic-host) -DELASTIC_PORT=$(elastic-port) -DINDEXER_HOST=$() -DENTITLEMENTS_DOMAIN=$(DOMAIN) -DSEARCH_HOST=$(SEARCH_URL)api/search/v2/ -DSTORAGE_HOST=$() -DINTEGRATION_TESTER=$(INTEGRATION_TESTER) -DAZURE_TESTER_SERVICEPRINCIPAL_SECRET=$(AZURE_TESTER_SERVICEPRINCIPAL_SECRET) -DAZURE_AD_TENANT_ID=$(AZURE_DEPLOY_TENANT) -DAZURE_AD_APP_RESOURCE_ID=$(AZURE_AD_APP_RESOURCE_ID)` |
| MAVEN_INTEGRATION_TEST_POM_FILE_PATH | `drop/deploy/testing/integration-tests/search-test-azure` |
| SERVICE_RESOURCE_NAME | `$(AZURE_SEARCH_SERVICE_NAME)` |




### Load Cosmos DB Integration Test Data

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


### Configure the ADO Charts and Service Pipelines

Create the pipelines and run things in this exact order.
> Ensure DNS is configured for your Gateway IP to DNS_HOST

- Add a Pipeline __chart-osdu-common__ -->  Repo: infra-azure-provisioning Path:`/charts/osdu-common/pipeline.yml` and execute it.
  - This pipeline will deploy to flux the common components which includes ingress.
  - Validate the URL is alive.  https://<your_dns_name>


- Add a Pipeline __service-partition__ -->  Repo: partition Path:`/devops/azure/pipeline.yml` and execute it.
  - This pipeline will deploy to flux the partition service.
  > Partition Service requires an execution call to set Partition Data Manually at this point.


- Add a Pipeline __entitlements-azure__ -->  Repo: entitlements-azure Path:`/devops/azure/pipeline.yml` and execute it.
  - This pipeline will have to be run twice for integration tests to pass due to a preload data issue.


- Add a Pipeline __legal__ -->  Repo: legal Path:`/devops/legal/pipeline.yml` and execute it.


- Add a Pipeline __indexer-queue__ -->  Repo: indexer-queue Path:`/devops/azure/pipeline.yml` and execute it.


- Add a Pipeline __storage__ -->  Repo: storage Path:`/devops/azure/pipeline.yml` and execute it.


- Add a Pipeline __indexer__ -->  Repo: indexer Path:`/devops/azure/pipeline.yml` and execute it.


- Add a Pipeline __search__ -->  Repo: search Path:`/devops/azure/pipeline.yml` and execute it.
