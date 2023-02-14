# Azure OSDU MVC - Central Resources Configuration

The `osdu` - `central_resources` environment template is intended to provision to Azure resources for OSDU which are typically central to the architecture and can't be removed without destroying the entire OSDU deployment.

__PreRequisites__

> If you have run the `common_prepare.sh` scripts then jump down to the section called Manually Provision.

Requires the use of [direnv](https://direnv.net/) for environment variable management.

Requires a preexisting Service Principal to be created to be used for this OSDU Environment.

```bash
ENV=$USER  # This is helpful to set to your expected OSDU environment name.
NAME="osdu-mvp-$ENV-principal"

# Create a Service Principal
az ad sp create-for-rbac --name $NAME --skip-assignment -ojson

# Result
{
  "appId": "<guid>",                # -> Use this for TF_VAR_principal_appId
  "displayName": "<name>",          # -> Use this for TF_VAR_principal_name
  "name": "http://<name>",
  "password": "****************",   # -> Use this for TF_VAR_principal_password
  "tenant": "<ad_tenant>"
}

# Retrieve the AD Service Pricipal ID
az ad sp list --display-name $NAME --query [].objectId -ojson

# Result
[
  "<guid>"                          # -> Use this for TF_VAR_principal_objectId
]


# Assign API Permissions
# Microsoft Graph -- Application Permissions -- Directory.Read.All  ** GRANT ADMIN-CONSENT
adObjectId=$(az ad app list --display-name $NAME --query [].objectId -otsv)
graphId=$(az ad sp list --query "[?appDisplayName=='Microsoft Graph'].appId | [0]" --all -otsv)
directoryReadAll=$(az ad sp show --id $graphId --query "appRoles[?value=='Directory.Read.All'].id | [0]" -otsv)=Role

az ad app permission add --id $adObjectId --api $graphId --api-permissions $directoryReadAll

# Grant Admin Consent
# ** REQUIRES ADMIN AD ACCESS **
az ad app permission admin-consent --id $appId
```

Set up your local environment variables

*Note: environment variables are automatically sourced by direnv*

Required Environment Variables (.envrc)
```bash
export ARM_TENANT_ID=""
export ARM_SUBSCRIPTION_ID=""

# Terraform-Principal
export ARM_CLIENT_ID=""
export ARM_CLIENT_SECRET=""

# Terraform State Storage Account Key
export TF_VAR_remote_state_account=""
export TF_VAR_remote_state_container=""
export ARM_ACCESS_KEY=""

# Instance Variables
export TF_VAR_resource_group_location="centralus"
```

Navigate to the `terraform.tfvars` terraform file. Here's a sample of the terraform.tfvars file for this template.

```HCL
prefix                  = "osdu-mvp"

resource_tags = {
   contact = "<your_name>"
}
```

__Manually Provision__

Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="cr-${UNIQUE}"
terraform workspace new $TF_WORKSPACE || terraform workspace select $TF_WORKSPACE
```

> Manually create a custom variable file to use for template configuration and edit as appropriate and desired.

```bash
# File location : /infra-azure-provisioning/infra/templates/osdu-r3-mvp/central_resources
cp terraform.tfvars custom.tfvars

# Do not run following commands if you wish to use ad application created/managed by terraform and
# you've used common_prepare.sh for initial setup. Also, it requires setting of AZURE_VAULT, ADO_PROJECT and UNIQUE env variables.
# These commands pull aad client id from common keyvault for the ad application created by common_prepare.sh. This aad client id is then used in terraform env.
# if you have created common infra manually without common_prepare.sh, then manually set aad_client_id = "your ad application client id" in custom.tfvars and do not run these commands.
TF_VAR_application_clientid=$(az keyvault secret show --id https://$AZURE_VAULT.vault.azure.net/secrets/${ADO_PROJECT}-${UNIQUE}-application-clientid --query value -otsv)
echo -e "aad_client_id = \"$TF_VAR_application_clientid\"" >> custom.tfvars
```

Execute the following commands to orchestrate a deployment.
If we want to enable BYOAD (Bring your own AD Application), please go through following wiki [byoad-enable](./../../../../docs/byoad-enable.md)

```bash
# See what terraform will try to deploy without actually deploying
terraform plan -var-file custom.tfvars

# Execute a deployment
terraform apply -var-file custom.tfvars
```

Optionally execute the following command to teardown your deployment and delete your resources.

```bash
# Destroy resources and tear down deployment. Only do this if you want to destroy your deployment.
terraform destroy
```

## Testing

Please confirm that you've completed the `terraform apply` step before running the integration tests as we're validating the active terraform workspace.

**Note:** Install gcc step as a prerequisite before performing unit tests.

Follow this link to install [GCC](https://gcc.gnu.org/install/index.html)


Unit tests can be run using the following command:

```
go test -v $(go list ./... | grep "unit")
```

Integration tests can be run using the following command:

```
go test -v $(go list ./... | grep "integration")
```
