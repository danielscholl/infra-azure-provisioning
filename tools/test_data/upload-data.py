#   Copyright © Microsoft Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.


from azure.cosmos import CosmosClient, PartitionKey
import json
import pprint
import os
import time

cosmos_url = os.environ['COSMOS_ENDPOINT']
cosmos_key = os.environ['COSMOS_KEY']
service_principal_id = os.environ['SERVICE_PRINCIPAL_ID']
service_principal_oid = os.environ['SERVICE_PRINCIPAL_OID']
no_data_access_tester = os.environ['NO_DATA_ACCESS_TESTER']

cosmos_client = CosmosClient(cosmos_url, credential = cosmos_key)
db = cosmos_client.get_database_client('osdu-db')


def tenant_info(db):
    container = db.get_container_client("TenantInfo")


    with open("./tenant_info_1.json", "r") as f :
      tenant_info_1 = json.load(f)
    with open("./tenant_info_2.json", "r") as f :
      tenant_info_2 = json.load(f)

    tenant_info_1["serviceprincipalAppId"] = service_principal_id
    tenant_info_2["serviceprincipalAppId"] = service_principal_id

    container.upsert_item(tenant_info_1)
    container.upsert_item(tenant_info_2)
    return

def user_info(db):
    container = db.get_container_client("UserInfo")

    with open("./user_info_1.json", "r") as f:
      user_info_1 = json.load(f)
    with open("./user_info_2.json", "r") as f :
      user_info_2 = json.load(f)

    user_info_1["id"] = service_principal_oid
    user_info_1["uid"] = service_principal_id
    user_info_2["id"] = no_data_access_tester

    container.upsert_item(user_info_1)
    container.upsert_item(user_info_2)
    return

def legal_tag(db):
    container = db.get_container_client("LegalTag")

    with open("./legal_tag_1.json", "r") as f:
        legal_tag_1 = json.load(f)
    with open("./legal_tag_2.json", "r") as f:
        legal_tag_2 = json.load(f)
    with open("./legal_tag_3.json", "r") as f:
        legal_tag_3 = json.load(f)

    container.upsert_item(legal_tag_1)
    container.upsert_item(legal_tag_2)
    container.upsert_item(legal_tag_3)
    return

def storage_schema(db):
    container = db.get_container_client("StorageSchema")

    with open("./storage_schema_1.json", "r") as f:
      storage_schema_1 = json.load(f)
    with open("./storage_schema_2.json", "r") as f:
      storage_schema_2 = json.load(f)
    with open("./storage_schema_3.json", "r") as f:
      storage_schema_3 = json.load(f)
    with open("./storage_schema_4.json", "r") as f:
      storage_schema_4 = json.load(f)
    with open("./storage_schema_5.json", "r") as f:
      storage_schema_5 = json.load(f)
    with open("./storage_schema_6.json", "r") as f:
      storage_schema_6 = json.load(f)
    with open("./storage_schema_7.json", "r") as f:
      storage_schema_7 = json.load(f)
    with open("./storage_schema_8.json", "r") as f:
      storage_schema_8 = json.load(f)
    with open("./storage_schema_9.json", "r") as f:
      storage_schema_9 = json.load(f)
    with open("./storage_schema_10.json", "r") as f:
      storage_schema_10 = json.load(f)
    with open("./storage_schema_11.json", "r") as f:
      storage_schema_11 = json.load(f)

    storage_schema_1["user"] = service_principal_id
    storage_schema_2["user"] = service_principal_id
    storage_schema_3["user"] = service_principal_id
    storage_schema_4["user"] = service_principal_id
    storage_schema_5["user"] = service_principal_id
    storage_schema_6["user"] = service_principal_id
    storage_schema_7["user"] = service_principal_id
    storage_schema_8["user"] = service_principal_id
    storage_schema_9["user"] = service_principal_id
    storage_schema_10["user"] = service_principal_id
    storage_schema_11["user"] = service_principal_id

    container.upsert_item(storage_schema_1)
    container.upsert_item(storage_schema_2)
    container.upsert_item(storage_schema_3)
    container.upsert_item(storage_schema_4)
    container.upsert_item(storage_schema_5)
    container.upsert_item(storage_schema_6)
    container.upsert_item(storage_schema_7)
    container.upsert_item(storage_schema_8)
    container.upsert_item(storage_schema_9)
    container.upsert_item(storage_schema_10)
    container.upsert_item(storage_schema_11)
    return


if __name__ == "__main__":
    tenant_info(db)
    user_info(db)
    legal_tag(db)
    storage_schema(db)
