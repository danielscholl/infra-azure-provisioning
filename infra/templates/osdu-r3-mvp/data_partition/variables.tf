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

/*
.Synopsis
   Terraform Variable Configuration
.DESCRIPTION
   This file holds the Variable Configuration
*/


#-------------------------------
# Application Variables
#-------------------------------
variable "prefix" {
  description = "The workspace prefix defining the project area for this terraform deployment."
  type        = string
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 4
}

variable "remote_state_account" {
  description = "Remote Terraform State Azure storage account name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "remote_state_container" {
  description = "Remote Terraform State Azure storage container name. This is typically set as an environment variable and used for the initial terraform init."
  type        = string
}

variable "central_resources_workspace_name" {
  description = "(Required) The workspace name for the central_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

variable "resource_tags_sdms" {
  description = "Map of tags to apply to sdms resources."
  type        = map(string)
  default     = { service = "sdms" }
}

variable "resource_group_location" {
  description = "The Azure region where data storage resources in this template should be created."
  type        = string
}

variable "data_partition_name" {
  description = "The OSDU data Partition Name."
  type        = string
  default     = "opendes"
}

variable "log_retention_days" {
  description = "Number of days to retain logs."
  type        = number
  default     = 30
}

variable "storage_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS*, GRS, RAGRS and ZRS."
  type        = string
  default     = "GZRS"
}

variable "storage_containers" {
  description = "The list of storage container names to create. Names must be unique per storage account."
  type        = list(string)
}

variable "storage_containers_hierarchical" {
  description = "The list of storage container names to create for hierarchical storage. Names must be unique per storage account."
  type        = list(string)
}

variable "airflow2_enabled" {
  description = "Feature flag for enabling airflow2"
  type        = bool
  default     = false
}

variable "storage_containers_dp_airflow" {
  description = "The list of storage container names to create for data partition airflow"
  type        = list(string)
}

variable "blob_cors_rule" {
  type = list(
    object(
      {
        allowed_origins    = list(string)
        allowed_methods    = list(string)
        allowed_headers    = list(string)
        exposed_headers    = list(string)
        max_age_in_seconds = number
  }))
  default     = []
  description = "List of CORS Rules to be applied on the Blob Service."
}

variable "cosmosdb_replica_location" {
  description = "The name of the Azure region to host replicated data. i.e. 'East US' 'East US 2'. More locations can be found at https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  type        = string
}

variable "cosmosdb_consistency_level" {
  description = "The level of consistency backed by SLAs for Cosmos database. Developers can chose from five well-defined consistency levels on the consistency spectrum."
  type        = string
  default     = "Session"
}

variable "cosmosdb_automatic_failover" {
  description = "Determines if automatic failover is enabled for CosmosDB."
  type        = bool
  default     = true
}

variable "cosmos_databases" {
  description = "The list of Cosmos DB SQL Databases."
  type = list(object({
    name       = string
    throughput = number
  }))
  default = []
}

variable "cosmos_sql_collections" {
  description = "The list of cosmos collection names to create. Names must be unique per cosmos instance."
  type = list(object({
    name                  = string
    database_name         = string
    partition_key_path    = string
    partition_key_version = number
  }))
  default = []
}

variable "sb_sku" {
  description = "The SKU of the namespace. The options are: `Basic`, `Standard`, `Premium`."
  type        = string
  default     = "Standard"
}

variable "sb_topics" {
  type = list(object({
    name                = string
    enable_partitioning = bool
    subscriptions = list(object({
      name               = string
      max_delivery_count = number
      lock_duration      = string
      forward_to         = string
    }))
  }))
  default = [
    {
      name                = "topic_test"
      enable_partitioning = true
      subscriptions = [
        {
          name               = "sub_test"
          max_delivery_count = 1
          lock_duration      = "PT5M"
          forward_to         = ""
        }
      ]
    }
  ]
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "endpoint for elasticsearch cluster"
}

variable "elasticsearch_username" {
  type        = string
  description = "username for elasticsearch cluster"
}

variable "elasticsearch_password" {
  type        = string
  description = "password for elasticsearch cluster"
}

variable "ssh_public_key_file" {
  type        = string
  description = "(Required) The SSH public key used to setup log-in credentials on the nodes in the AKS cluster."
}

variable "feature_flag" {
  description = "(Optional) A toggle for incubator features"
  type = object({
    storage_mgmt_policy_enabled = bool
  })
  default = {
    storage_mgmt_policy_enabled = false
  }
}

variable "deploy_dp_airflow" {
  description = "Flag to deploy Airflow Infrastructure in Data Partition Resource Group"
  type        = bool
  default     = false
}

variable "service_resources_workspace_name" {
  description = "(Required) The workspace name for the service_resources repository terraform environment / template to reference for this template."
  type        = string
}

variable "sa_retention_days" {
  description = "Number of days that to retain data in file-staging-area"
  type        = number
  default     = 30
}

variable "ssl_challenge_required" {
  description = "Flag to indicate whether http01 ssl challenge is required"
  type        = bool
  default     = true
}

variable "cosmos_primary_loc" {
  description = "Fix for cosmos location."
  type        = string
  default     = null
}

variable "reservoir_ddms" {
  description = "Reservoir DDMS properties and enable flag"
  type = object({
    enabled = bool
    sku     = string
  })
  default = {
    enabled = false
    sku     = "GP_Gen5_4"
  }
}

variable "dp_airflow_aks_version_prefix" {
  description = "(Optional) AKS version for the AKS airflow2 resources, ignored if deploy_dp_airflow is disabled"
  type        = string
  default     = "1.25"
}

variable "cosmosdb_backup_redundancy" {
  description = "The storage redundancy which is used to indicate type of backup residency."
  type        = string
  default     = "Geo"
}
