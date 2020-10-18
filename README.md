# infra-azure-provisioning

This repository contains the infrastructure as code implementation and pipelines necessary for the required infrastructure to host OSDU on Azure.

The `osdu` - R3 MVP Architecture solution template is intended to provision Managed Kubernetes resources like AKS and other core OSDU cloud managed services like Cosmos, Blob Storage and Keyvault.

## Cloud Resource Architecture

![Architecture](./docs/images/architecture.png "Architecture")


## Cost

Azure environment cost ballpark [estimate](https://tinyurl.com/y4e9s7rf). This is subject to change and is driven from the resource pricing tiers configured when the template is deployed.


## Prerequisites

1. Azure Subscription
1. Terraform and Go are locally installed.
1. Requires the use of [direnv](https://direnv.net/).
1. Install the required common tools (kubectl, helm, and terraform).  


### Install the required tooling

This document assumes one is running a current version of Ubuntu. Windows users can install the Ubuntu Terminal from the Microsoft Store. The Ubuntu Terminal enables Linux command-line utilities, including bash, ssh, and git that will be useful for the following deployment. _Note: You will need the Windows Subsystem for Linux installed to use the Ubuntu Terminal on Windows_.


Currently the versions in use are [Terraform 0.12.29](https://releases.hashicorp.com/terraform/0.12.29/) and [GO 1.12.14](https://golang.org/dl/).

> Note: Terraform and Go are recommended to be installed using a [Terraform Version Manager](https://github.com/tfutils/tfenv) and a [Go Version Manager](https://github.com/stefanmaric/g)


### Install the Azure CLI

For information specific to your operating system, see the [Azure CLI install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). You can also use the single command install if running on a Unix based machine.

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login to Azure CLI and ensure subscription is set to desired subscription
az login
az account set --subscription <your_subscription>
```


### Configure and Work with an Azure Devops Project

Configure an Azure Devops Project in your Organization called `osdu-mvp` and set the cli command to use the organization by default.

```bash
export ADO_ORGANIZATION=<organization_name>
export ADO_PROJECT=osdu-mvp

# Ensure the CLI extension is added
az extension add --name azure-devops

# Setup a Project Space in your organization
az devops project create --name $ADO_PROJECT --organization $ADO_ORGANIZATION

# Configure the CLI Defaults to work with the organization and project
az devops configure --defaults organization=https://dev.azure.com/$ADO_ORGANIZATION project=$ADO_PROJECT
```

## Clone the repository

It is recommended to work with this repository in a WSL Ubuntu directory structure.

```bash
git clone git@community.opengroup.org:osdu/platform/deployment-and-operations/infra-azure-provisioning.git

cd infra-azure-provisioning
```


## Create a Flux Manifest Repository

[Create an empty git repository](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-new-repo?view=azure-devops) with a name that clearly signals that the repo is used for the Flux manifests. For example `k8-gitops-manifests`.

Flux requires that the git repository have at least one commit. Initialize the repo with an empty commit.

```bash
export ADO_REPO=k8-gitops-manifests

# Initialize a Git Repository
(mkdir k8-gitops-manifests \
  && cd k8-gitops-manifests \
  && git init \
  && git commit --allow-empty -m "Initializing the Flux Manifest Repository")

# Create an ADO Repo
az repos create --name $ADO_REPO
export GIT_REPO=git@ssh.dev.azure.com:v3/${ADO_ORGANIZATION}/${ADO_PROJECT}/k8-gitops-manifests

# Push the Git Repository
(cd k8-gitops-manifests \
  && git remote add origin $GIT_REPO \
  && git push -u origin --all)
```


## Provision the Common Resources

The script `common_prepare.sh` script is a _helper_ script designed to help setup some of the common things that are necessary for infrastructure.

- Ensure you are logged into the azure cli with the desired subscription set.
- Ensure you have the access to run az ad commands.

```bash
# Execute Script
export UNIQUE=demo

./infra/common_prepare.sh $(az account show --query id -otsv) $UNIQUE
```


__Local Script Output Resources__

The script creates some local files to be used.

1. .envrc_{UNIQUE} -- This is a copy of the required environment variables for the common components.
2. .envrc -- This file is used directory by direnv and requires `direnv allow` to be run to access variables.
3. ~/.ssh/osdu_{UNIQUE}/azure-aks-gitops-ssh-key -- SSH key used by flux.
4. ~/.ssh/osdu_{UNIQUE}/azure-aks-gitops-key.pub -- SSH Public Key used by flux.
5. ~/.ssh/osdu_{UNIQUE}/azure-aks-gitops-key.passphrase -- SSH Key Passphrase used by flux.
6. ~/.ssh/osdu_{UNIQUE}/azure-aks-node-ssh-key -- SSH Key used by AKS
7. ~/.ssh/osdu_{UNIQUE}/azure-aks-node-ssh-key.pub -- SSH Public Key used by AKS
8. ~/.ssh/osdu_{UNIQUE}/azure-aks-node-ssh-key.passphrase -- SSH Key Passphrase used by AKS

> Ensure environment variables are loaded `direnv allow`

__Installed Azure Resources__

1. Resource Group
2. Storage Account
3. Key Vault
4. A principal to be used for Terraform _(Requires Grant Admin Approval)_
5. A principal to be used for the OSDU environment.
6. An application to be used for the OSDU environment. _(future)_
7. An application to be used for negative integration testing.

> Removal would require deletion of all AD elements `osdu-mvp-{UNIQUE}-*`, unlocking and deleting the resource group then purging the KV.


__Azure AD Admin Consent__

2 service principals have been created that need to have an AD Admin `grant admin consent` on.

1. osdu-mvp-{UNIQUE}-terraform  _(Azure AD Application Graph - Application.ReadWrite.OwnedBy)_
2. osdu-mvp-{UNIQUE}-principal _(Microsoft Graph - Directory.Read.All)_



## Elastic Search Setup

Infrastructure requires a bring your own Elastic Search Instance of a version of 6.8.x with a valid https endpoint and the access information must now be stored in the Common KeyVault. The recommended method of Elastic Search is to use the [Elastic Cloud Managed Service from the Marketplace](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/elastic.ec-azure?tab=Overview).

> Note: Elastic Cloud Managed Service requires a Credit Card to be associated to the subscription for billing purposes.

```bash
ES_ENDPOINT=""
ES_USERNAME=""
ES_PASSWORD=""
az keyvault secret set --vault-name $COMMON_VAULT --name "elastic-endpoint-dp1-demo" --value $ES_ENDPOINT
az keyvault secret set --vault-name $COMMON_VAULT --name "elastic-username-dp1-demo" --value $ES_USERNAME
az keyvault secret set --vault-name $COMMON_VAULT --name "elastic-password-dp1-demo" --value $ES_PASSWORD

cat >> .envrc << EOF

# https://cloud.elastic.co
# ------------------------------------------------------------------------------------------------------
export TF_VAR_elasticsearch_endpoint="$(az keyvault secret show --id https://$COMMON_VAULT.vault.azure.net/secrets/elastic-endpoint-dp1-demo --query value -otsv)"
export TF_VAR_elasticsearch_username="$(az keyvault secret show --id https://$COMMON_VAULT.vault.azure.net/secrets/elastic-username-dp1-demo --query value -otsv)"
export TF_VAR_elasticsearch_password="$(az keyvault secret show --id https://$COMMON_VAULT.vault.azure.net/secrets/elastic-password-dp1-demo --query value -otsv)"

EOF

cp .envrc .envrc_${UNIQUE}
```


## Configure Key Access in Manifest Repository

The public key of the `azure-aks-gitops-ssh-key` previously created needs to be added as a deploy key in your Azure DevOPS Project, follow these [steps](https://docs.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops&tabs=current-page#step-2--add-the-public-key-to-azure-devops-servicestfs) to add your public SSH key to your ADO environment.

```bash
# Retrieve the public key
az keyvault secret show \
  --id https://$COMMON_VAULT.vault.azure.net/secrets/azure-aks-gitops-ssh-key-pub \
  --query value \
  -otsv
```


## Automated Pipeline Installation

> This typically takes about 3 hours to complete.

1. Configure the Pipelines following directions [here](./docs/pipeline-setup.md).

2. Manually configure your DNS_HOST to the IP Address of the environment IP Address.

3. Deploy the application helm charts following the directions [here]().



## Manual Installation

> This typically takes about 2 hours to complete.

1. Install the Infrastructure following directions [here](./infra/templates/osdu-r3-mvp/README.md).

2. Manually configure your DNS_HOST to the IP Address of the environment IP Address.

3. Deploy the application helm charts following the directions [here](./charts/README.md).



## Developer Activities

1. To onboard new services follow the process located [here](./docs/service-onboarding.md).
