- [Modules](#modules)

- [Templates](#templates)

- [Directory Structure](#directory-structure)

# Modules

Modules are the building blocks of templates. A module is a thin wrapper that enable simple common-sense configuration of related resources (typically 1-3 but sometimes more) within a cloud provider. These modules are implemented as [Terraform Modules](https://www.terraform.io/docs/configuration/modules.html).


# Templates

Templates are the implementation of *Advocated Patterns.* The scope of a template typically covers most of if not all of the infrastructure required to host an application and may provision resources in multiple cloud provider. Templates compose modules to create an advocated pattern. They are implemented as [Terraform Modules](https://www.terraform.io/docs/configuration/modules.html) so that they can be composed if needed, though it is more commonly the case that they need not be composed.



# Directory Structure

The directory structure of Cobalt enalbes contributions for a variety of cloud providers.

```bash
$ tree -d
.
├── modules
│   └── providers
│       └── azure
│           ├── ad-application
│           ├── aks
│           ├── app-insights
│           ├── app-monitoring
│           ├── appgw
│           ├── container-registry
│           ├── cosmosdb
│           ├── event-grid
│           ├── keyvault
│           ├── keyvault-cert
│           ├── keyvault-policy
│           ├── keyvault-secret
│           ├── log-analytics
│           ├── network
│           ├── postgreSQL
│           ├── redis-cache
│           ├── resource-group
│           ├── service-bus
│           ├── service-principal
│           └── storage-account
└── templates
    └── osdu-r3-mvp
        ├── central_resources
        │   └── tests
        │       ├── integration
        │       └── unit
        ├── data_partition
        │   └── tests
        │       ├── integration
        │       └── unit
        └── service_resources
            └── tests
                ├── integration
                └── unit
```

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
