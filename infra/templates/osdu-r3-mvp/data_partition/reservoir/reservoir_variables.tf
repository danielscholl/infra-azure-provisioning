variable "resource_group_name" {
  description = "Resource Group Name of the data partition resources"
  type        = string
}

variable "postgres_sku" {
  type        = string
  default     = "GP_Gen5_4"
  description = "SKU for the reservoir DB"
}

variable "postgres_rbac_principals" {
  type        = list(string)
  description = "List of principals which does need access to the PostgresSql"
}

variable "data_partition_name" {
  description = "The OSDU data Partition Name for the secret identifier"
  type        = string
}

variable "cr_keyvault_id" {
  description = "Keyvault Id to store reservoir secrets (common resources keyvault)"
  type        = string
}

variable "resource_tags" {
  description = "Map of tags to apply to this template."
  type        = map(string)
  default     = {}
}
