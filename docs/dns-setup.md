# DNS Setup

Manually update your DNS A Records to point to the Public IP Address for the environment.

```bash
# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# Get IP Address
RESOURCE_GROUP=$(az group list --query "[?contains(name, 'sr${UNIQUE}')].name" -otsv |grep -v MC)
az network public-ip list --resource-group $RESOURCE_GROUP --query [].ipAddress -otsv
```
