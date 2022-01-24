# Airflow2 migration guide

This document outlines the process of upgrading existing airflow 1.10.12 setup to Airflow2.

## Approach
We have opted for a incremental approach where airflow 1.10.12 installation remain and fresh airflow2 installation is deployed, reusing the component where possible.

### Before Upgrading
As the Metadata is stored separately for Airflow1.x and airflow2.x, we will not be able to query the completion status of the DAG's post migration.
The following steps need before migration:
1. We need to stop the creation of new `Dags` and `Triggers` for the Dags.
2. Status of all workflow run needs to be updated in the Workflow Service.

### Upgrading Airflow2
There are 2 methods that can be chosen to perform installation at this point in time.

1. Manual Upgrade -- Typically used when the desire is to manually make modifications to the environment and have full control all updates and deployments.
2. Pipeline Upgrade -- Typically used when the need is to only access the Data Platform but allow for automatic upgrades of infrastructure and services.


### Upgrading Manual installation ( preferred approach)
 1. Run infra [setup](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/infra/templates/osdu-r3-mvp/service_resources/README.md) to create necessary infra for the airflow2 setup.
 2. Follow [documentation](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/blob/master/osdu-airflow2/README.md) to deploy airflow2 using helm chart.
 3. Validate airflow2 is up and running at {osdu_endpoint}/airflow2 endpoint
 4. Copy the latest community DAG's to the `airflowdags` to `airflow2dags`. Any custom DAG's need to be [upgraded](https://airflow.apache.org/docs/apache-airflow/stable/upgrading-from-1-10/index.html#step-5-upgrade-airflow-dags) to airflow2.
 5. Validate the uploaded dags are getting parse by airflow and are visible in the airflow webserver UI.
 6. Deploy workflow service using `helm-chart-azure` as described in the [document](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/tree/master/osdu-azure/workflow#airflow-2-migration).

### Automated Pipeline Installation
 1. Trigger the [`infrastructure-service-resources`](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/docs/infra-automation.md) pipeline to create infrastructure required for airflow2.
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
 3. Validate airflow2 is up and running at {osdu_endpoint}/airflow2 endpoint
 4. Copy the latest community DAG's to the `airflowdags` to `airflow2dags`. Any custom DAG's need to be [upgraded](https://airflow.apache.org/docs/apache-airflow/stable/upgrading-from-1-10/index.html#step-5-upgrade-airflow-dags) to airflow2..
 5. Validate the uploaded dags are getting parse by airflow and are visible in the airflow webserver UI.
 6. Deploy workflow service using `helm-chart-azure` as described in the [document](https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-workflow/-/tree/master/provider/workflow-azure#airflow-2-migration).


 ### Reverting back to Airflow 1
As the airflow 1 installation in not removed we could revert back to the airflow1 deployment by switching the flags in [value.yaml](https://community.opengroup.org/osdu/platform/data-flow/ingestion/ingestion-workflow/-/blob/master/devops/azure/chart/values.yaml#L25) in ingestion-workflow.

|  name | value |
| ---  | ---   |
| `osduAirflowURL` | `http://airflow-web:8080/airflow` |
| `airflowVersion2Enabled` | `false` |


Redeploy the `workflow-service` after the changes.

### Cleanup Airflow 1.10x.
Once the Upgrade to airflow2 is concluded, airflow1 installation can removed.

We can remove Airflow1 installation by deleting the following has components:
1. Airflow1 webserver pods
2. Airflow1 scheduler pods
3. Airflow1 workers pods
4. fileshare
5. Application Gateway Rules

To remove the above components we can

1. For pipeline deployment
   by removing the components from flux repo
2. For Manual deployment:
   by invoking `helm delete <type> <component> -n <namespace>`

   1. helm delete deployments airflow-web -n osdu
   2. helm delete deployments airflow-scheduler -n osdu
   3. helm delete statefulsets airflow-worker -n osdu
   4. helm delete deployments airflow-pgbouncer -n osdu

Metadata and Logs will be preserved, as metadata is kept in postgres and logs in log analytics.
