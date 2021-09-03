# Enable BYOAD

We've added a feature flag to enable or disable auto-creation of ad-application in central resources.

# Updating existing infra to have custom AD Application
Doing this will make current auth and refresh codes invalid. They'll need to be generated again.
1. Set enable_bring_your_own_ad_app=true in custom values file for terraform apply in central resources.
2. Post success of terraform apply for central resources, add application id of custom ad application to aad-client-id key in central resources keyvault.
3. Users with automated pipeline should now run chart chart-osdu-istio and chart-osdu-istio-auth pipeline.
4. Users with manual deployment need to re-install osdu-istio helm chart with new app-id.
5. Delete all pods in the portal AKS. This will trigger a restart of all pods. Complete steps 5,6 and 7 in quick procession.
6. While all pods are getting restarted, move to configuration in portal AKS. Select secrets tab and choose osdu/osdu-azure namespace.
7. Delete active-directory from the results. This will trigger its recreation.
8. Delete all pods again to make sure that new pods are using new active directory secrets.
9. Run this script with required values substituted - [subscriberCreationRegisterService](./Trouble%20Shooting%20Guides/tsg-scripts/subscriberCreationRegisterService.ps1)