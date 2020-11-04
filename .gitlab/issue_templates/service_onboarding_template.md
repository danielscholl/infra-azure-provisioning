**Service name**:

## Prerequisites:

**[YES/NO]** the service is passing integration tests locally using code from master branch.

**[YES/NO]** the service pipeline has been created and tested to see that it works and passes integration tests. See [here](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/docs/service-onboarding.md) for more details.

**[YES/NO]** the service helm chart has been created and tested to see that it works and that the deployed service will pass integration tests. See [here](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/docs/service-onboarding.md) for more details.

## Steps:

**Infrastructure Onboarding**
- [ ] Identify any additional Infrastructure changes and document as 
Infrastructure level requirements.  
_Examples: Cosmos collections, Storage containers_
- [ ] Obtain approval for any infrastructure requirements.
- [ ] Implement any required infrastructure changes.
- [ ] Obtain approval for merge request(s) containing infrastructure changes.

**Chart Onboarding**
- [ ] Identify any additional chart changes and document as chart level requirements.  
_Examples: [Ingress](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/charts/osdu-common/templates/appgw-ingress.yaml), [Secrets](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/charts/osdu-common/templates/kv-secrets.yaml), [Istio Auth Policies](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/tree/master/charts/osdu-istio-auth/templates)._
- [ ] Obtain Approval for any chart requirements.
- [ ] Implement any required chart changes.
- [ ] Obtain approval for merge request(s) containing chart changes.

**Integration Test Onboarding**
- [ ] Identify any additional integration test data requirements.
- [ ] Implement test data changes.  
_Integration test data is in the [test data](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/tree/master/tools/test_data) directory_
- [ ] Obtain approval for merge request(s) containing test data changes.

**Manual Onboarding**
- [ ] Create script to generate developer variables.  
_This script will generate the files that store the variables that developers need to develop and integration test services. Look at the [variables](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/tree/master/tools/variables) directory where the script will be stored to use the scripts for other services as models_
- [ ] Update documentation for manual deployments.  
_The documentation for manually deploying services that you need to update is [here](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/charts/README.md)._

**Automation Onboarding**
- [ ] Add the new service the the [code mirroring instructions](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/docs/code-mirroring.md).
- [ ] Create and document how to create a library group for your service. Each service has a library group that is require dto deploy and test the service. You can find examples on the [service automation](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/docs/service-automation.md) instructions page.
- [ ] Create and document how to create a pipeline for your service.  
_For each service there are instructions on the [service automation](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/docs/service-automation.md) page for how to easily set up the pipeline in each services respective repository._