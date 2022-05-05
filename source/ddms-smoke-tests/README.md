# Azure DDMS Testing
## Description
This folder contains Azure Smoke tests for DDMS services and related components

## Prerequisites
You should have [Postman](https://learning.postman.com/docs/getting-started/introduction/) and / or [newman](https://learning.postman.com/docs/running-collections/using-newman-cli/command-line-integration-with-newman/) installed 

## How to run
If your are using `Postman` to run the tests, please update `OIDC_CLIENT_SECRET` in environment file with actual value.


You can also use `newman`
```sh
export OIDC_CLIENT_SECRET='...'

newman run "Azure DDMS OSDU Smoke Tests.postman_collection.json" \
-e "[Ship] osdu-glab.msft-osdu-test.org.postman_environment.json" \
--env-var "OIDC_CLIENT_SECRET=$OIDC_CLIENT_SECRET"

```