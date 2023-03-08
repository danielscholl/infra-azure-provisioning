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

package test

import (
	"os"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	appGatewayIntegTests "github.com/microsoft/cobalt/infra/modules/providers/azure/appgw/tests/integration"
	redisIntegTests "github.com/microsoft/cobalt/infra/modules/providers/azure/redis-cache/tests/integration"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var subscription = os.Getenv("ARM_SUBSCRIPTION_ID")
var backendNetworkAccessEnabled = os.Getenv("TF_VAR_public_network_access_enabled")
var tfOptions = &terraform.Options{
	TerraformDir: "../../",
	BackendConfig: map[string]interface{}{
		"storage_account_name": os.Getenv("TF_VAR_remote_state_account"),
		"container_name":       os.Getenv("TF_VAR_remote_state_container"),
	},
}

// Runs a suite of test assertions to validate that a provisioned data source environment
// is fully functional.
func TestDataEnvironment(t *testing.T) {
	if len(backendNetworkAccessEnabled) == 0 {
		backendNetworkAccessEnabled = "false"
	}
	var testFixture infratests.IntegrationTestFixture
	if backendNetworkAccessEnabled == "true" {
		testFixture = infratests.IntegrationTestFixture{
			GoTest:                t,
			TfOptions:             tfOptions,
			ExpectedTfOutputCount: 18,
			TfOutputAssertions: []infratests.TerraformOutputValidation{
				redisIntegTests.InspectProvisionedCache("redis_name", "services_resource_group_name"),
				redisIntegTests.InspectProvisionedCache("redis_queue_name", "services_resource_group_name"),
				redisIntegTests.CheckRedisWriteOperations("redis_hostname", "redis_primary_access_key", "redis_ssl_port"),
				redisIntegTests.CheckRedisWriteOperations("redis_queue_hostname", "redis_queue_primary_access_key", "redis_queue_ssl_port"),
				appGatewayIntegTests.InspectAppGateway("services_resource_group_name", "appgw_name", "keyvault_secret_id"),
			},
		}
	} else {
		testFixture = infratests.IntegrationTestFixture{
			GoTest:                t,
			TfOptions:             tfOptions,
			ExpectedTfOutputCount: 18,
			TfOutputAssertions: []infratests.TerraformOutputValidation{
				appGatewayIntegTests.InspectAppGateway("services_resource_group_name", "appgw_name", "keyvault_secret_id"),
			},
		}
	}

	infratests.RunIntegrationTests(&testFixture)
}
