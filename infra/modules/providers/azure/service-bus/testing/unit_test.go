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

package unit

//might be package test
import (
	"encoding/json"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/microsoft/cobalt/test-harness/infratests"
)

var workspace = "osdu-services-" + strings.ToLower(random.UniqueId())
var count = 6

var tfOptions = &terraform.Options{
	TerraformDir: "./",
	Upgrade:      false,
}

// helper function to parse blocks of JSON into a generic Go map
func asMap(t *testing.T, jsonString string) map[string]interface{} {
	var theMap map[string]interface{}
	if err := json.Unmarshal([]byte(jsonString), &theMap); err != nil {
		t.Fatal(err)
	}
	return theMap
}

func TestTemplate(t *testing.T) {

	expectedSBNamespace := map[string]interface{}{
		"capacity": 0.0,
		"sku":      "Standard",
		"tags": map[string]interface{}{
			"source": "terraform",
		},
	}

	expectedSubscription := map[string]interface{}{
		"name":               "sub_test",
		"max_delivery_count": 1.0,
		"lock_duration":      "PT5M",
		"dead_lettering_on_filter_evaluation_error": true,
	}

	expectedTopic := map[string]interface{}{
		"name":                "topic_test",
		"enable_partitioning": true,
		"status":              "Active",
	}

	testFixture := infratests.UnitTestFixture{
		GoTest:                t,
		TfOptions:             tfOptions,
		Workspace:             workspace,
		PlanAssertions:        nil,
		ExpectedResourceCount: count,
		ExpectedResourceAttributeValues: infratests.ResourceDescription{
			"module.service_bus.azurerm_servicebus_namespace.main":       expectedSBNamespace,
			"module.service_bus.azurerm_servicebus_topic.main[0]":        expectedTopic,
			"module.service_bus.azurerm_servicebus_subscription.main[0]": expectedSubscription,
		},
	}
	infratests.RunUnitTests(&testFixture)
}
