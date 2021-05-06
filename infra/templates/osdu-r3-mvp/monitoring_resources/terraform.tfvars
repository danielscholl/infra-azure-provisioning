//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

prefix      = "osdu-mvp"
tenant_name = "<your_tenant_name>"

dashboards = {
  default     = true
  appinsights = true
}

# Populated below is a collection of sample action groups.
action-groups = {
  DevActionGroup = {
    name       = "DevActionGroup",
    short-name = "dev-ag",
    email-receiver = [
      {
        name                = "primary receiver",
        email-address       = "xxxx",
        common-alert-schema = false
      },
      {
        name                = "secondary receiver",
        email-address       = "xxxx",
        common-alert-schema = false
      }
    ],
    sms-receiver = []
  },
  ProdActionGroup = {
    name           = "ProdActionGroup",
    short-name     = "prod-ag",
    email-receiver = [],
    sms-receiver = [
      {
        name         = "local support",
        country-code = "xx",
        phone        = "xxxxxx"
      }
    ]
  }
}

# Populated below is data to configure a sample alert.
log-alerts = {
  #------------Storage Service Alerts----------------#
  storage-cpu-alert = {
    service-name    = "storage",
    alert-rule-name = "CPU Soft limit",
    description     = "CPU Soft limit alert rule for storage service",
    # Alert based on metric measurement
    metric-type       = true
    enabled           = "false",
    severity          = 3,
    frequency         = 15,
    time-window       = 15,
    action-group-name = ["ProdActionGroup", "DevActionGroup"],
    query             = "performanceCounters\n| where cloud_RoleName == \"storage\"\n| where category == \"Processor\" and name == \"% Processor Time\"\n| summarize AggregatedValue = avg(value) by bin(timestamp, 15min)",
    # Threshold value for CPU usage which when exceeded will raise alert
    trigger-threshold       = 60,
    trigger-operator        = "GreaterThan",
    metric-trigger-operator = "GreaterThan",
    # Number of times the threshold value is allowed to exceed
    metric-trigger-threshold = 0,
    # Type can be based on total breaches or consecutive breaches of threshold.
    metric-trigger-type   = "Total",
    metric-trigger-column = "timestamp"
  }
}
