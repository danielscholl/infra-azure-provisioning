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

output "name" {
  value       = var.aad_client_id != "" ? null : azuread_application.main[0].display_name
  description = "The display name of the application."
}

output "id" {
  value       = var.aad_client_id != "" ? null : azuread_application.main[0].application_id
  description = "The ID of the application."
}

output "object_id" {
  value       = var.aad_client_id != "" ? null : azuread_application.main[0].object_id
  description = "The object ID of the application."
}

output "roles" {
  value = var.aad_client_id != "" ? null : {
    for r in azuread_application.main[0].app_role :
    r.display_name => {
      id          = r.id
      name        = r.display_name
      value       = r.value
      description = r.description
      enabled     = r.is_enabled
    }
  }
  description = "The application roles."
}

output "password" {
  value       = var.aad_client_id != "" ? null : azuread_application_password.main.0.value
  sensitive   = true
  description = "The password for the application."
}
