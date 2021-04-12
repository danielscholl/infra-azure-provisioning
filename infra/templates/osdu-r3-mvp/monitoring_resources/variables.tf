//  Copyright � Microsoft Corporation
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

variable "prefix" {
  description = "(Required) An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "dashboards" {
  description = "(Optional) A toggle for dashboards"
  type = object({
    default     = bool
    appinsights = bool
  })
  default = {
    default     = true
    appinsights = true
  }
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 4
}

variable "central_resources_workspace_name" {
  description = "(Required) The workspace name for the central_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "service_resources_workspace_name" {
  description = "(Required) The workspace name for the central_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "data_partition_resources_workspace_name" {
  description = "(Required) The workspace name for the central_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "remote_state_account" {
  description = "Remote Terraform State Azure storage account name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "remote_state_container" {
  description = "Remote Terraform State Azure storage container name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "resource_group_location" {
  description = "(Required) The Azure region where all resources in this template should be created."
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

variable "tenant_name" {
  description = "(Required) The Azure AD tenant name."
  type        = string
}

#-------------------------------
# Alerts
#-------------------------------
variable "cpu-usage-threshold" {
  description = "Threshold value beyond which alert needs to be triggered"
  type        = number
  default       = 1
}

variable "metric-trigger-threshold" {
  description = "Threshold of the metric trigger. Here, number of times cpu usage is allowed to reach cpu-usage-threshold."
  type        = number
  default       = 0
}

variable "time-window" {
  description = "Time window for which data needs to be fetched for query (must be greater than or equal to frequency)."
  type        = number
  default       = 30
}

variable "severity" {
  description = "Severity of alert. Possible values are 0, 1, 2, 3 and 4"
  type        = number
  default       = 3
}

variable "frequency" {
  description = "The evaluation frequency of this Metric Alert, represented in ISO 8601 duration format. Possible values are PT1M, PT5M, PT15M, PT30M and PT1H. Defaults to PT1M"
  type        = number
  default       = 5
}

variable "query" {
  description = "Log query"
  type        = string
  default       = "performanceCounters\n| where category == \"Processor\" and name == \"% Processor Time\"\n| summarize AggregatedValue = avg(value) by bin(timestamp, 15min), cloud_RoleName"
}

variable "email-id" {
  description = "Email id at which alerts will be sent"
  type        = string
  default       = "vibsharm@microsoft.com"
}
