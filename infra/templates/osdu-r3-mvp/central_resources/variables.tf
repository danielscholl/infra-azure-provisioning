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
  description = "(Required) An identifier used to construct the names of all resources in this template."
  type        = string
}

variable "feature_flag" {
  description = "(Optional) A toggle for incubator features"
  type = object({
    kv_lock  = bool
    acr_lock = bool
  })
  default = {
    kv_lock  = true
    acr_lock = true
  }
}

variable "aad_client_id" {
  description = "Existing Application AppId."
  type        = string
  default     = ""
}

variable "randomization_level" {
  description = "Number of additional random characters to include in resource names to insulate against unexpected resource name collisions."
  type        = number
  default     = 4
}

variable "resource_group_location" {
  description = "The Azure region where container registry resources in this template should be created."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs."
  type        = number
  default     = 30
}

variable "container_registry_sku" {
  description = "(Optional) The SKU name of the the container registry. Possible values are Basic, Standard and Premium."
  type        = string
  default     = "Standard"
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}

variable "principal_name" {
  description = "Existing Service Principal Name."
  type        = string
}

variable "principal_password" {
  description = "Existing Service Principal Password."
  type        = string
}

variable "principal_appId" {
  description = "Existing Service Principal AppId."
  type        = string
}

variable "principal_objectId" {
  description = "Existing Service Principal ObjectId."
  type        = string
}

variable "storage_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS*, GRS, RAGRS and ZRS."
  type        = string
  default     = "LRS"
}

variable "storage_allow_nested_items_to_be_public" {
  description = "(Optional) Allow or disallow nested items within this Account to opt into being public."
  type        = bool
  default     = false
}

variable "cosmosdb_replica_location" {
  description = "The name of the Azure region to host replicated data. i.e. 'East US' 'East US 2'. More locations can be found at https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  type        = string
  default     = null
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

variable "cosmos_graph_databases" {
  description = "The list of Cosmos DB Graph Databases."
  type = list(object({
    name       = string
    throughput = number
  }))
  default = null
}

variable "cosmos_graphs" {
  description = "The list of cosmos graphs to create. Names must be unique per cosmos instance."
  type = list(object({
    name               = string
    database_name      = string
    partition_key_path = string
  }))
  default = []
}