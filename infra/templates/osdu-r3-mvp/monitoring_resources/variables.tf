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
  description = "(Required) The workspace name for the service_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "data_partition_resources_workspace_name" {
  description = "(Required) The workspace name for the data_partition_resources repository terraform environment / template to reference for this template."
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

variable "action-groups" {
  type = map(object({
    name       = string,
    short-name = string,
    email-receiver = list(object({
      name                = string,
      email-address       = string,
      common-alert-schema = bool
    })),
    sms-receiver = list(object({
      name         = string,
      country-code = string,
      phone        = string
    }))
  }))
}

variable "log-alerts" {
  type = map(object({
    service-name    = string,
    alert-rule-name = string,
    description     = string,
    # Alert can be based on metric measurement or based on number of results.
    metric-type       = bool,
    enabled           = string,
    severity          = number,
    frequency         = number,
    time-window       = number,
    action-group-name = list(string),
    query             = string,
    trigger-threshold = number,
    trigger-operator  = string,
    # Type is `any` for the below keys as they need to be null if alert is based on number of results
    metric-trigger-operator  = any,
    metric-trigger-threshold = any,
    metric-trigger-type      = any,
    metric-trigger-column    = any
  }))
}