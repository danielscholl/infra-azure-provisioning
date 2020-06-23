# infra-azure-provisioning

Azure Infrastructure provisioning scripts and templates are hosted in a Gihthub repository that is accessible here:
[Azure Infrastructure Templates](https://github.com/azure/osdu-infrastructure)

The repository contains the infrastructure as code implementation and pipelines necessary for the required infrastructure in Azure to host OSDU. The infrastructure code is very closely tied to Azure, and requires degree of priviledges and access and leverages capability inherent to Azure DevOps, hence the Gitlab hosting. Unfortunately this high level of integration could not be entirely accomodated out of Gitlab.

The current approach to deploying OSDU into your own Azure tenant involves the following step:
1- Follow the directions in the infrastructure repository to deploy the infrastructure
2- Deploy the services using a mirrored Azure Devops project (instructions in [here](https://github.com/azure/osdu-infrastructure))
3- Load the data
