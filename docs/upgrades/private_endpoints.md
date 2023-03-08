# Private endpoints

The feature allows to close network access to some of the backend resources as described in [#246](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/issues/246).

* Ensure that public network access is disabled in Redis Cache
* Ensure that Redis Cache uses private link

## Close accesses to the backend resources

You can disable public network access by using flag `backend_network_access_enabled = false` in [service_resources/terraform.tfvars](../../infra/templates/osdu-r3-mvp/service_resources/terraform.tfvars).

* **Redis behavior**
  * `backend_network_access_enabled = true` redis instance will be reachable publicly as well as through private endpoint, however the AKS communication from nodes to redis will be through private endpoint.
  * `backend_network_access_enabled = false` redis instance will **NOT** be reachable publicly only throug private endpoint communication AKSNodes -> redis.
  * This setting applies for all the backend redis instances.

## Warnings and downtimes (Brownfield deployments)

### Redis private endpoints

When the `Service Resources` terraform scripts are applied, the pods using redis needs to be restarted to refresh the dns-cache for the azure sdk to use private link or new ip address assigned to the redis resource.

```shell
kubectl delete pods -n osdu-azure -l "app in (entitlements,legal,storage,search,partition)"
kubectl rollout restart deploy airflow2-web airflow2-scheduler -n airflow2
kubectl rollout restart sts airflow2-worker -n airflow2
```
