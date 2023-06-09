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
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var tfOptions = &terraform.Options{
	TerraformDir: "../../",
	Upgrade:      true,
	Vars: map[string]interface{}{
		"resource_group_location": region,
		"prefix":                  prefix,
	},
	BackendConfig: map[string]interface{}{
		"storage_account_name": os.Getenv("TF_VAR_remote_state_account"),
		"container_name":       os.Getenv("TF_VAR_remote_state_container"),
	},
}

var deploy_dp_airflow = os.Getenv("TF_VAR_deploy_dp_airflow")
var airflow_dp_resource_count = 88
var expected_resource_count = 149

func TestTemplate(t *testing.T) {

	expectedAppDevResourceGroup := asMap(t, `{
		"location": "`+region+`"
	}`)

	resourceDescription := infratests.ResourceDescription{
		"azurerm_resource_group.main": expectedAppDevResourceGroup,
	}

	if deploy_dp_airflow == "true" {
		expected_resource_count = expected_resource_count + airflow_dp_resource_count
	}

	testFixture := infratests.UnitTestFixture{
		GoTest:                          t,
		TfOptions:                       tfOptions,
		Workspace:                       workspace,
		PlanAssertions:                  nil,
		ExpectedResourceCount:           expected_resource_count,
		ExpectedResourceAttributeValues: resourceDescription,
	}

	infratests.RunUnitTests(&testFixture)
}
