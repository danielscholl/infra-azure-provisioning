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

**Note:** Running the ZGY and/or VDS Smoke Tests locally will require the *sample-ST10010ZC11_PZ_PSDM_KIRCH_FULL_T.MIG_FIN.POST_STACK.3D.JS-017536.segy* file in the directory. This file is write-locked to preserve integrity and you must use [Large File  Storage](https://docs.gitlab.com/ee/topics/git/lfs/) (LFS) to fetch the file with the following git command:

```sh
git lfs fetch origin <branchname>
```
