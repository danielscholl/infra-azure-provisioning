# Gitlab OSDU Azure Provider README Template
This is a template for Azure provider READMEs for OSDU service Gitlab repos. To implement this template for a service, copy the content below in this file into `$SERVICE_DIRECTORY/provider/$SERVICE-azure/README` (or equivalent) file and fill in the highlighted information throughout the document. 

# <service_name>-azure
> Fill in <service_name> above. Add service description here

## Requirements

In order to run this service locally, you will need the following:

- [Maven 3.6.0+](https://maven.apache.org/download.cgi)
- [AdoptOpenJDK8](https://adoptopenjdk.net/)
- [OSDU on Azure infrastructure](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning) deployed
> Add any additional requirements here

## Service Dependencies
- [Service A]()
- [Service B]()
- [Service C]() (required by Service B)

> Add service dependencies here

## Entitlements

| name | description 
| ---  | ---   |
| `example.entitlement.x` | Entitles users to access endpoint a |
| `example.entitlement.y` | Entitles users to access endpoint b |
> Fill in this table describing any entitlements required by users


## General Tips

**Environment Variable Management**
The following tools make environment variable configuration simpler
 - [direnv](https://direnv.net/) - for a shell/terminal environment
 - [EnvFile](https://plugins.jetbrains.com/plugin/7861-envfile) - for [Intellij IDEA](https://www.jetbrains.com/idea/)

**Lombok**
This project uses [Lombok](https://projectlombok.org/) for code generation. You may need to configure your IDE to take advantage of this tool.
 - [Intellij configuration](https://projectlombok.org/setup/intellij)
 - [VSCode configuration](https://projectlombok.org/setup/vscode)


## Environment Variables

In order to run the service locally, you will need to have the following environment variables defined. We have created a helper script to generate .yaml files to set the environment variables to run and test the service using the InteliJ IDEA plugin and generate a .envrc file to set the environment variables to run and test the service using direnv [here]().
> Add link to service environment variable script above

**Note** The following command can be useful to pull secrets from keyvault:
```bash
az keyvault secret show --vault-name $KEY_VAULT_NAME --name $KEY_VAULT_SECRET_NAME --query value -otsv
```

**Required to run service**

| name | value | description | sensitive? | source |
| ---  | ---   | ---         | ---        | ---    |
| `EXAMPLE_CONSTANT` | `VALUE` | Description | no | Constant |
| `EXAMPLE_VARIBLE` | `https://$DNS_NAME/endpoint/` | Description | no | Adding `/endpoint/` to DNS name for environment
| `EXAMPLE_ENVIRONMENT_SECRET` | `******` | Description | yes | Value of `secret_name` in environment keyvault |
| `EXAMPLE_COMMON_SECRET` | `******` | Description | yes | Value of `secret_name` in common keyvault |
> Fill this in with required values for the service and double check that the listed source is correct. Be aware that services are not consistent about requiring a trailing / for urls, so be particularly careful that all URLs have an accurate model in the "value" column.

**Required to run integration tests**

| name | value | description | sensitive? | source |
| ---  | ---   | ---         | ---        | ---    |
> Same as above

## Running Locally

### Configure Maven

Check that maven is installed:
```bash
$ mvn --version
Apache Maven 3.6.0
Maven home: /usr/share/maven
Java version: 1.8.0_212, vendor: AdoptOpenJDK, runtime: /usr/lib/jvm/jdk8u212-b04/jre
...
```

### Build and run the application

After configuring your environment as specified above, you can follow these steps to build and run the application. These steps should be invoked from the repository root.

```bash
# build + test + install core service code from repository root
$ mvn clean install

# build + test + package azure service code
$ (cd provider/$SERVICE-azure/ && mvn clean package)

# run service from repository root
#
# Note: this assumes that the environment variables for running the service as outlined above are already exported in your environment.
$ java -jar $(find provider/$SERVICE-azure/target/ -name '*-spring-boot.jar')

```
> Fill in value for $SERVICE above and verify that the commands work for this service

### Test the Application

_After the service has started it should be accessible via a web browser by visiting [http://localhost:8080/$SWAGGER_ENDPOINT.html](http://localhost:8080/$SWAGGER_ENDPOINT). If the request does not fail, you can then run the integration tests._
> Fill in value for $SWAGGER_ENDPOINT above

```bash
# build + install integration test core
$ (cd testing/$SERVICE-test-core/ && mvn clean install)

# build + run Azure integration tests.
#
# Note: this assumes that the environment variables for integration tests as outlined above are already exported in your environment.
$ (cd testing/$SERVICE-test-azure/ && mvn clean test)
```
> Fill in value for $SERVICE above and verify that the commands work for this service

### Debugging

Jet Brains - the authors of Intellij IDEA, have written an [excellent guide](https://www.jetbrains.com/help/idea/debugging-your-first-java-application.html) on how to debug java programs.

## License
Copyright © Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
