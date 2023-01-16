# DNS Setup

You can use the appgw `fqdn` by default in case you don't need your custom domain name, by default this will be the endpoint exposed for the azure osdu applications I.E: `osdu-mvp-srxxx-xxxx-istio-gw.centralus.cloudapp.azure.com`.

## Custom domain name

In case you need custom domain name, you need to setup the `aks_dns_host` variable custom domain name when deploying [Service Resources](../infra/templates/osdu-r3-mvp/service_resources/).

This can be setup either in the [terraform.tfvars](../infra/templates/osdu-r3-mvp/service_resources/terraform.tfvars) file or as a environment variable (`export TF_VAR_aks_dns_host="your.own.domain.name.org"`).

Manually update your DNS (with your DNS provider) A Records to point to the Public IP Address for the environment.

```bash
# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# Get IP Address and FQDN from istio appgw
RESOURCE_GROUP=$(az group list --query "[?contains(name, 'sr${UNIQUE}-')].name" -otsv |grep -v MC)
az network public-ip list --resource-group $RESOURCE_GROUP --query "[?contains(id,'istio')].{IpAddress:ipAddress, FQDN:dnsSettings.fqdn}" -otable
```

You can either:

* Register the __Istio AppGw__ ip address as AAA record in your dns provider.
* Register FQDN as ALIAS record with your DNS provider.
