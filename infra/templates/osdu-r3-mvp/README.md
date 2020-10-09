# Azure OSDU R3 MVP Architecture

The `osdu` - R3 MVP Architecture solution template is intended to provision Managed Kubernetes resources like AKS and other core OSDU cloud managed services like Cosmos, Blob Storage and Keyvault.

## Cloud Resource Architecture

![Architecture](./docs/images/architecture.png "Architecture")


## Cost

Azure environment cost ballpark [estimate](). This is subject to change and is driven from the resource pricing tiers configured when the template is deployed.


## Prerequisites

1. Azure Subscription
1. An available Service Principal capable of creating resources.
1. Terraform and Go are locally installed.
1. Requires the use of [direnv](https://direnv.net/).
1. Install the required common tools (kubectl, helm, and terraform).  Note: Currently uses [Terraform 0.12.29](https://releases.hashicorp.com/terraform/0.12.29/).


### Install the required tooling

This document assumes one is running a current version of Ubuntu. Windows users can install the Ubuntu Terminal from the Microsoft Store. The Ubuntu Terminal enables Linux command-line utilities, including bash, ssh, and git that will be useful for the following deployment. _Note: You will need the Windows Subsystem for Linux installed to use the Ubuntu Terminal on Windows_.


### Install the Azure CLI

For information specific to your operating system, see the [Azure CLI install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). You can also use [this script](https://github.com/microsoft/bedrock/blob/master/tools/prereqs/setup_azure_cli.sh) if running on a Unix based machine.


## Provision the Common Resources

The script ./common_prepare.sh will conveniently setup the common things that are necessary to install infrastructure.
- Run the script with your subscription ID as the first argument and an optional unique string as the second argument.
- Note the files (azure-aks-gitops-ssh-key and azure-aks-node-ssh-key.pub) that have appeared in the .ssh directory.
You will need these in a later step.
- Note the output of this script creates a .envrc file used with `direnv` to automatically setup the required environment for installation.

> UNIQUE is used to generate uniqueness across all of azure.  _(3-5 characters)_

```bash
export ARM_SUBSCRIPTION_ID=<your_subscription_id>
export UNIQUE=<your_unique>

./common_prepare.sh
```

This results in 2 service principals being created that need an AD Admin to `grant admin consent` on.

1. osdu-mvp-{UNIQUE}-terraform
2. osdu-mvp-{UNIQUE}-principal

__Installed Common Resources__

1. Resource Group
2. Storage Account
3. Key Vault
4. A principal to be used for Terraform _(Requires Grant Admin Approval)_
5. A principal to be used for the OSDU environment.
6. An application to be used for the OSDU environment. _(future)_
7. An application to be used for negative integration testing.

>Note: 2 Users are required to be created in AD for integration testing purposes manually and values stored in this Common Key Vault.


## Elastic Search Setup

Infrastructure assumes bring your own Elastic Search Instance at a version of 6.8.x and access information must be stored in the Common KeyVault.

```bash
ENDPOINT=""
USERNAME=""
PASSWORD=""
az keyvault secret set --vault-name $COMMON_VAULT --name "elastic-endpoint-ado-demo" --value $ENDPOINT
az keyvault secret set --vault-name $COMMON_VAULT --name "elastic-username-ado-demo" --value $USERNAME
az keyvault secret set --vault-name $COMMON_VAULT --name "elastic-password-ado-demo" --value $PASSWORD

cat >> .envrc_${UNIQUE} << EOF

# https://cloud.elastic.co
# ------------------------------------------------------------------------------------------------------
export TF_VAR_elasticsearch_endpoint="$(az keyvault secret show --vault-name $COMMON_VAULT --id https://$COMMON_VAULT.vault.azure.net/secrets/elastic-endpoint-ado-demo --query value -otsv)"
export TF_VAR_elasticsearch_username="$(az keyvault secret show --vault-name $COMMON_VAULT --id https://$COMMON_VAULT.vault.azure.net/secrets/elastic-username-ado-demo --query value -otsv)"
export TF_VAR_elasticsearch_password="$(az keyvault secret show --vault-name $COMMON_VAULT --id https://$COMMON_VAULT.vault.azure.net/secrets/elastic-password-ado-demo --query value -otsv)"

EOF

cp .envrc_${UNIQUE} .envrc
```


## Create the Flux Manifest Repository

[Create an empty git repository](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-new-repo?view=azure-devops) with a name that clearly signals that the repo is used for the Flux manifests. For example `k8-gitops-manifests`.

Flux requires that the git repository have at least one commit. Initialize the repo with an empty commit.

```bash
git commit --allow-empty -m "Initializing the Flux Manifest Repository"
```


## Configure Key Access in Manifest Repository

The public key of the [RSA key pair](#create-an-rsa-key-pair-for-a-deploy-key-for-the-flux-repository) previously created needs to be added as a deploy key. Note: _If you do not own the repository, you will have to fork it before proceeding_.

Use the contents of the Secret as shown above.

Next, in your Azure DevOPS Project, follow these [steps](https://docs.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops&tabs=current-page#step-2--add-the-public-key-to-azure-devops-servicestfs) to add your public SSH key to your ADO environment.


## Manual Deployment Process
Follow these steps if you wish to deploy manually without pipeline support.

__Deploy Central Resources__

Follow the directions in the [`central_resources`](./central_resources/README.md) environment.

__Deploy Data Resources__

Follow the directions in the [`data_resources`](./data_partition/README.md) environment.

__Deploy Service Resources__

Follow the directions in the [`service_resources`](./service_resources/README.md) environment.

## License

Copyright © Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
