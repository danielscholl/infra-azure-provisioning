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

// topics_flattend is used to create the map of Topic Name to Topic Id.
locals {
  topics_flattened = flatten([
  for topic in azurerm_servicebus_topic.main : [
    {
      key   = topic.name
      value = topic.id
    }
  ]
  ])
}

output "name" {
  value       = azurerm_servicebus_namespace.main.name
  description = "The namespace name."
}

output "id" {
  value       = azurerm_servicebus_namespace.main.id
  description = "The namespace ID."
}

output "default_connection_string" {
  description = "The primary connection string for the authorization rule RootManageSharedAccessKey which is created automatically by Azure."
  value       = azurerm_servicebus_namespace.main.default_primary_connection_string
}

output "authorization_rules" {
  value = merge({
    for rule in azurerm_servicebus_namespace_authorization_rule.main :
    rule.name => {
      name                        = rule.name
      primary_key                 = rule.primary_key
      primary_connection_string   = rule.primary_connection_string
      secondary_key               = rule.secondary_key
      secondary_connection_string = rule.secondary_connection_string
    }
    }, {
    default = local.default_authorization_rule
  })
  description = "Map of authorization rules."
  sensitive   = true
}

output "topics" {
  value = {
    for topic in azurerm_servicebus_topic.main :
    topic.name => {
      id   = topic.id
      name = topic.name
      authorization_rules = {
        for rule in azurerm_servicebus_topic_authorization_rule.main :
        rule.name => {
          name                        = rule.name
          primary_key                 = rule.primary_key
          primary_connection_string   = rule.primary_connection_string
          secondary_key               = rule.secondary_key
          secondary_connection_string = rule.secondary_connection_string
        } if topic.name == rule.topic_name
      }
    }
  }
  description = "Map of topics."
}

output "queues" {
  value = {
    for queue in azurerm_servicebus_queue.main :
    queue.name => {
      id   = queue.id
      name = queue.name
      authorization_rules = {
        for rule in azurerm_servicebus_queue_authorization_rule.main :
        rule.name => {
          name                        = rule.name
          primary_key                 = rule.primary_key
          primary_connection_string   = rule.primary_connection_string
          secondary_key               = rule.secondary_key
          secondary_connection_string = rule.secondary_connection_string
        } if queue.name == rule.queue_name
      }
    }
  }
  description = "Map of queues."
}

output "topicsmap" {
  description = "The Topic Name to Topic Id map for the given list of topics."
  value       = { for item in local.topics_flattened : item.key => item.value }
}