# Airflow2 migration guide

This document outlines the process of upgrading existing airflow 1.10.12 setup to Airflow2.

## Approach
We have opted for a incremental approach where airflow 1.10.12 installation remain and fresh airflow2 installation is deployed, reusing the component where possible.


### Upgrading Airflow2
There are 2 methods that can be chosen to perform installation at this point in time.

1. Manual Upgrade -- Typically used when the desire is to manually make modifications to the environment and have full control all updates and deployments.
2. Pipeline Upgrade -- Typically used when the need is to only access the Data Platform but allow for automatic upgrades of infrastructure and services.


### Manual upgrading step ( preferred approach)
 1. Run infra [setup](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/tree/master/infra/templates/osdu-r3-mvp) to create necessary infra for the airflow2 setup.
 2. Follow [documentation](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/blob/master/osdu-airflow2/README.md) to deploy airflow2 using helm chart.
 3. Validate airflow2 is up and running at {base_url}/airflow2 endpoint
 4. Copy the Existing DAG's to the `airflowdags` to `airflow2dags` after upgrading the DAG's to airflow2.
 5. Validate the uploaded dags are getting parse by airflow and are visible in the airflow webserver UI.
 6. Deploy workflow service as described in the [document](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/tree/master/osdu-azure/workflow#airflow-2-migration).

### Automated Pipeline Installation
 1. Trigger the `infrastructure-service-resources` pipeline to create infrastructure required for airflow2
 2. Create new pipeline for the airflow2 deployment using
 Repo: `infra-azure-provisioning` Path: `/devops/pipelines/chart-airflow2.yml`.Validate: Airflow Pods are running except for airflow-setup-default-user which is a job pod.

    ```sh
    az pipelines create \
    --name 'chart-airflow2'  \
    --repository infra-azure-provisioning  \
    --branch master  \
    --repository-type tfsgit  \
    --yaml-path /devops/pipelines/chart-airflow2.yml  \
    -ojson
    ```
 3. Validate airflow2 is up and running at {base_url}/airflow2 endpoint
 4. Copy the Existing DAG's to the `airflowdags` to `airflow2dags` after upgrading the DAG's to airflow2.
 5. Validate the uploaded dags are getting parse by airflow and are visible in the airflow webserver UI.
 6. Deploy workflow service as described in the [document](https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-workflow/-/tree/master/provider/workflow-azure#airflow-2-migration).


 ### Reverting back to Airflow 1
As the airflow 1 installation in not removed we could revert to the deployment to point at switching `OSDU_AIRFLOW_VERSION2_ENABLED` to `False`
 redeploy the workflow service flag to target the airflow 1.10.12 deployment.


### How to cleanup airflow1 infrastructure after migration
If all dags seems to work fine then the airflow 1 installation can be decommissioned or kept for the historical purpose. To Cleanup the airflow1 installation the following resources need to be removed:
 - fileshare dir - airflowdags
 - postgres db namespace - db name airflow
 - application gateway rules targeting airflow 1
