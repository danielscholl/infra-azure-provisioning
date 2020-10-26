# Service Level Environment Variables

This project hosts the service environment variables patterns.

__PreRequisites__

Requires the use of [direnv](https://direnv.net/).

__Log with environment ServicePrincipal__

The application created for OSDU by default does not have a Client Secret and one must be manually created.

```bash
# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

export DNS_HOST=<your_fqdn>
export COMMON_VAULT=<your_common_vault>
```

__Create Service Environment Variables__

Generate the environment .envrc and yaml files compatable with intelliJ [envfile](https://plugins.jetbrains.com/plugin/7861-envfile) plugin.

```bash
for SERVICE in partition entitlements-azure legal storage indexer-queue indexer-service search-service;
do
  ./$SERVICE.sh
done
```

