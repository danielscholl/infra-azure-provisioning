# Terraform upgrade from 0.14 to 1.3.4

__WARN__ Go to the backend Storage account `(commonXXXX) > remote-state-container > *tfstate` and take a snapshot of each state files or create version for each state file

```text
 # terraform version
Terraform v1.3.4
on linux_amd64
```

```text
pushd infra-azure-provisioning/infra/templates/osdu-r3-mvp/central_resources/
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}" -upgrade
terraform plan -out /tmp/tf.out
terraform apply -auto-apprve /tmp/tf.out
```

## golang upgrade from 1.12 -> 1.18.8

It should be straight forward step, no issues encountered during version upgrade.
