## Upgade keda version from <=2.2.0 to >=2.2.1 (in osdu case 2.2.0 to 2.7.2)
Documentation: [keda-docs/troubleshooting/helm-upgrade-crd.md](https://github.com/tomkerkhove/keda-docs/blob/main/content/troubleshooting/helm-upgrade-crd.md)  
When terraform is trying to upgrade keda
```
  # helm_release.keda will be updated in-place
  ~ resource "helm_release" "keda" {
        id                         = "keda"
        name                       = "keda"
      ~ version                    = "2.2.0" -> "2.7.2"
```
it might fail with the next error:
```
helm_release.keda: Still modifying... [id=keda, 20s elapsed]
Error: rendered manifests contain a resource that already exists. Unable to continue with update: CustomResourceDefinition "scaledjobs.keda.sh" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata; label validation error: missing key "app.kubernetes.io/managed-by": must be set to "Helm"; annotation validation error: missing key "meta.helm.sh/release-name": must be set to "keda"; annotation validation error: missing key "meta.helm.sh/release-namespace": must be set to "keda"
  on helm_keda.tf line 34, in resource "helm_release" "keda":
  34: resource "helm_release" "keda" {
```
As per documentation link above - it is known keda upgrade issue. To fix it - run the next command (once for each environment) to apply the lables required to for keda upgrade.  
Command is idempotent so can be added to pipeline as well:
```shell
for ii in $(kubectl get crd --no-headers -o custom-columns=":metadata.name" | grep ".keda.sh"); do
  kubectl patch crd ${ii} --patch '{
                                      "metadata": {
                                        "annotations": {
                                          "meta.helm.sh/release-name": "keda",
                                          "meta.helm.sh/release-namespace": "keda"
                                        },
                                        "labels": {
                                          "app.kubernetes.io/managed-by": "Helm"
                                        }
                                      }
                                    }';
done
```

## Upgade keda version from 1.5 to 2.x

### [Outdated] Infra deployment steps 
Note: Infrastructure has already permanently enabled keda v2 and we dropped support of this feature flag.
> We've used feature flag to upgrade keda version from 1.5 to 2.x osdu infra on azure.
> A user can follow following steps to upgrade keda version - 
> 
> 1. We've set keda_v2_enabled field in feature_flag variable in service resource to false.
> It represents that currently osdu infra is currently using 1.5 version.
> 2. If using flux, reduce replica count to 0 for flux deployment until step 4. (use command - kubectl edit deployment flux -n flux)
> 3. Either run it or follow the steps in this script - infra/scripts/keda_upgrade_and_host_encryption.sh. 
>    This script requires some inputs. Feel free to edit the script as per requirement.
> 4. Override keda_v2_enabled field to true.



### Service deployment steps for manual users - 
1. We've added a variable named (keda.version_2_enabled: false) in Values.yaml for following files in helm-charts-azure repo-
    - osdu-airflow/values.yaml
    - osdu-azure/osdu-core_services/values.yaml 
    - osdu-azure/osdu-ingest_enrich/values.yaml 
    
2. Override (keda.version_2_enabled: false) value to true.
3. Make the deployment.

Service deployment steps for automated pipeline users - 
1. We've added a variable named (keda.version_2_enabled: false) in Values.yaml in indexer-queue repo.
2. Override (keda.version_2_enabled: false) value here to true.
3. Make the deployment
   
    
