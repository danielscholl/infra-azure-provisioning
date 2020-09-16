# infra-azure-provisioning

Azure Infrastructure provisioning scripts and templates are hosted in a Github repository that is accessible here:
[Azure Infrastructure Templates](https://github.com/azure/osdu-infrastructure)

The repository contains the infrastructure as code implementation and pipelines necessary for the required infrastructure in Azure to host OSDU. The infrastructure code is very closely tied to Azure, and requires degree of priviledges and access and leverages capability inherent to Azure DevOps, hence the GitHub hosting. Unfortunately this high level of integration could not be entirely accomodated out of Gitlab.

The current approach to deploying OSDU into your own Azure tenant involves the following step:
1- Follow the directions in the infrastructure repository to deploy the infrastructure
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

### Create the Helm Chart for the Service

Each service is responsible to maintain the helm chart necessary to install the service.  Charts for services are typically very similar but unique variables exist in the deployment.yaml that would be different for each services, additionally some files have service specific names that have to be modified from service to service.

```
├── devops
│   ├── azure
│   │   ├── README.md
│   │   ├── chart
│   │   │   ├── Chart.yaml
│   │   │   ├── templates
│   │   │   │   ├── deployment.yaml
│   │   │   │   └── service.yaml
│   │   │   └── values.yaml
│   │   └── release.yaml
```

### Execute the pipeline

Execute the pipeline and the service should now build, deploy and start.  Validate that the service has started successfully.

### Update the Ingress Controller

If the service has a public ingress the service ingress needs to be updated which can be found in the osdu-common chart.

> Currently this chart does not have automation on it and the helm chart template would need to be extracted and checked in manually to the flux directory for the environment.

### Update the Developer Variables

Each service typically needs specific variables necessary to start the service and test the service.  These developer variables need to be updated so that other developers have the ability to work with the service locally.

### Validate Integration Tests

Using the Developer Variables the deployed service needs to be validated that all integration tests pass successfully and the required variables have been identified.

### Update the Azure Cloud Provider CI/CD Template and enable testing

Once the service can be integration tested successfully any additional variables necessary for testing need to be updated in the `cloud-providers/azure.yml` file.

Remove the `AZURE_SKIP_TESTS` variable at the project and execute the pipeline
