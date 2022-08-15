# probe-test-client

This repository contains code that tests a deployment of OSDU. The main purpose of these tests is not to test the functionality of the services themselves, but rather to test that all the services are connected properly. Because of this, the tests only make calls that will engage other services (ie calling a data upload call to ensure storage is connected).

### Creating Your Own Tests

1.	In `config.js`, add service URL prefix in `api_host`. Add flags in test_flags section if needed.
2.	In `utils/testUtils.js`, under the constant services, add the new service to be tested. The format is keeping the key as the service name, with members name which is the service name as a string, host which makes up the request url for the service, `request(config.api_host.<service_name_added_in_step_1>)`, and api which’ll have the metadata of the APIs within the service. Each API will have the key as an api identifier, with members name with the api name, path to denote the API url path post the service prefix url. In case of complex paths, we can have a prefix and suffix within the path construct. Lastly, the API will have the member expectedResponse which’ll be a single value in case of `GET` or an array of objects in case of any other class of requests.
3.	Any data files required by test can be added to the folder `testData`.
4.	A new js file should be added to the folder scenarios for this new service scenario.

### Running the Tests

In order to run the tests you must first populate `docker-compose.yaml` with the appropriate values.

```bash
version: '3'
services:
  probetest:
    build:
      context: .
      dockerfile: Dockerfile
    image: msosdu.azurecr.io/osdu-probe:$VERSION
    environment:
      TERM: xterm
      TENANT_ID: $TENANT_ID
      PRINCIPAL_ID: $PRINCIPAL_ID
      PRINCIPAL_SECRET: $PRINCIPAL_SECRET
      CLIENT_ID: $CLIENT_ID
      SUBSCRIPTION_ID: $SUBSCRIPTION_ID
      OSDU_HOST: $OSDU_HOST
      APPINSIGHTS_INSTRUMENTATIONKEY: $APPINSIGHTS_INSTRUMENTATIONKEY
      VERSION: $VERSION
```
After filling `docker-compose.yaml` with the appropriate values, the tests can be run by running the command:
```bash
docker-compose up --build
```

### Running DDMS BVTs

In order to run tests for specific DDMS', please use the [Azure DDMS OSDU Smoke Tests collection](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/blob/master/source/ddms-smoke-tests/Azure%20DDMS%20OSDU%20Smoke%20Tests.postman_collection.json) instead.
