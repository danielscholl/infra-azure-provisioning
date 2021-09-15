# Enable BYOAD

We've added a feature flag (aad_client_id) to enable or disable auto-creation of ad-application in central resources.

# Updating existing infra to have custom AD Application
Doing this will make current auth and refresh codes invalid. They'll need to be generated again.
1. Users with manual deployment, if already not set, set aad_client_id = {{application client id of the custom ad application created}} in custom values file for terraform apply in central resources.
2. Users with automated pipeline -
   1. . Go to Pipelines Library in ADO
   2. Go to `Infrastructure Pipeline Variables - demo` variable group
   3. Add or update the below variable if already not set

    | Variable | Value |
      |----------|-------|
    | TF_VAR_aad_client_id | {{application client id of manually created ad application}} |

3. Users with automated pipeline should now run chart chart-osdu-istio and chart-osdu-istio-auth pipeline.
4. Users with manual deployment need to re-install osdu-istio helm chart with new app-id.
5. Delete all pods in the portal AKS. This will trigger a restart of all pods. Complete steps 5,6 and 7 in quick procession.
6. While all pods are getting restarted, move to configuration in portal AKS. Select secrets tab and choose osdu/osdu-azure namespace.
7. Delete active-directory from the results. This will trigger its recreation.
8. Delete all pods again to make sure that new pods are using new active directory secrets.
9. Run this script with required values substituted - [subscriberCreationRegisterService](./Trouble%20Shooting%20Guides/tsg-scripts/subscriberCreationRegisterService.ps1)