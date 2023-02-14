# HTTP Rest Scripts

These are HTTP Rest Scripts that can make testing and executing API calls easier.  These scripts are compatable with the VS Code Extension [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client).

[Rest Client Settings](https://github.com/Huachao/vscode-restclient#environment-variables) can be set to create environments and saved in [VS Code Settings](https://vscode.readthedocs.io/en/latest/getstarted/settings/).

__Create a Client Secret__

The application created for OSDU by default does not have a Client Secret and one must be manually created.

```bash
# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

GROUP=$(az group list --query "[?contains(name, 'cr${UNIQUE}')].name" -otsv)
ENV_VAULT=$(az keyvault list --resource-group $GROUP --query [].name -otsv)
PARTITION_NAME=<partition_name> # Replace with name of the data partition

CLIENT_SECRET=$(az ad app credential reset --id $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/aad-client-id --query value -otsv) --query password -otsv)
```
**Note:** Manually add client secret in azure portal if the above scripts fails.

__Retrieve Environment Settings__

```bash
# This will print settings that can be used in VS Code Preferences for the environment
cat  << EOF
"rest-client.environmentVariables": {
    "${UNIQUE}": {
      "TENANT_ID": "$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/tenant-id --query value -otsv)",
      "PRINCIPAL_ID": "$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/app-dev-sp-username --query value -otsv)",
      "PRINCIPAL_SECRET": "$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/app-dev-sp-password --query value -otsv)",
      "CLIENT_ID": "$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/aad-client-id --query value -otsv)",
      "CLIENT_SECRET": "$CLIENT_SECRET",
      "OSDU_HOST": "",
      "REGION": "${TF_VAR_resource_group_location}",
      "ES_HOST": "$(echo $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/opendes-elastic-endpoint --query value -otsv) \
                   | sed 's/^.\{8\}//g' | sed 's/.\{5\}$//')",
      "ES_AUTH_TOKEN": "$(echo $(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/opendes-elastic-username --query value -otsv):$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/opendes-elastic-password --query value -otsv) | base64)",
      "INITIAL_TOKEN": "<put refresh token here from auth_token.http authorize request>",
      "DATA_PARTITION_SERVICE_BUS_NAME": "$(az keyvault secret show --id https://${ENV_VAULT}.vault.azure.net/secrets/${PARTITION_NAME}-sb-namespace --query value -otsv)"
    }
}
EOF
```

__Retrieve Additional Values__

The `INITIAL_TOKEN` is an open id token.  Follow the directions in [osduauth](./osduauth) to obtain a token and once obtained save the value in settings.

The `OSDU_HOST` is your FQDN for your osdu environment.
