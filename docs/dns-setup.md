# DNS Setup

Manually update your DNS A Records to point to the Public IP Address for the environment.

```bash
# Get IP Address
RESOURCE_GROUP=$(az group list --query "[?contains(name, '${UNIQUE}sr')].name" -otsv |grep -v MC)
az network public-ip list --resource-group $RESOURCE_GROUP --query [].ipAddress -otsv
```
