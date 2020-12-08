**Note:** This file is manually edited and is best effort information at this time.

# v0.4.0 (2020-11-12)

__Description__

_Milestone 1 Tag Generated across all services._

__Branch/Tag__

[release/0.4](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/tree/release/0.4)

__Images__

| Service | Image | Tag |
| ------- | ----- | --- |
| Partition     | `community.opengroup.org:5555/osdu/platform/system/partition/partition-release-0-4` | 81976630aa9de9abd508a32a7f0ef1f9a773a1ab |
| Entitlements  | `community.opengroup.org:5555/osdu/platform/security-and-compliance/entitlements-azure/entitlements-azure-release-0-4` | 32fb4035378213354dedb90bb1549deb44e5f2df |
| Legal         | `community.opengroup.org:5555/osdu/platform/security-and-compliance/legal/legal-release-0-4` | 96dd3c699e0fa344a69e63acd75c83bafadab94f |
| Storage       | `community.opengroup.org:5555/osdu/platform/system/storage/storage-release-0-4` | 4eb302c39db1956d2e5098ec87399526176d14a5 |
| Indexer-Queue | `community.opengroup.org:5555/osdu/platform/system/indexer-queue/indexer-queue-release-0-4` | a3ea5d8629fed60058332672d7b871606041ee96 |
| Indexer       | `community.opengroup.org:5555/osdu/platform/system/indexer-service/indexer-service-release-0-4` | c1cde375c3c76e84290efb63405edf81ec964ff3 |
| Search        | `community.opengroup.org:5555/osdu/platform/system/search-service/search-service-release-0-4` | 834269ff32812c3cdfc42f315d3c7eb01fda622e |

__Infrastructure__

This infrastructure release is the initial porting of infrastructure from Github to Gitlab.

- Common Resources creation script
- Terraform Modules to support MVP Architecture
- Terraform Template osdu-r3-mvp/central_resources
- Terraform Template osdu-r3-mvp/data-partition
- Terraform Template osdu-r3-mvp/service-resources


__Devops__

- Common Devops Tasks and Templates to Support Infrastructure, Charts and Services
- Infrastructure Pipelines
- Custom Pipelines


__Charts__

- osdu-common
- osdu-istio
- osdu-istio-auth


__New Services__

- Partition
- Entitlements
- Legal
- Storage
- Indexer-Queue
- Indexer
- Search



# v0.4.1 (2020-11-30)

__Description__

_Additional Services Added._

__Branch/Tag__

[tag/0.4.1](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/tags/v0.4.1)


__Images__

| Service | Image | Tag |
| ------- | ----- | --- |
| Partition     | `community.opengroup.org:5555/osdu/platform/system/partition/partition-master` | 3a50a7048c7dd39ef689e87af6ee745f5a57b3b3 |
| Entitlements  | `community.opengroup.org:5555/osdu/platform/security-and-compliance/entitlements-azure/entitlements-azure-master` | 70b889b47be7ed01956db0305ad888e61e06387c |
| Legal         | `community.opengroup.org:5555/osdu/platform/security-and-compliance/legal/legal-master` | 70abc2ab72050a9795e63d6900f2b5f825173ad7 |
| Storage       | `community.opengroup.org:5555/osdu/platform/system/storage/storage-master` | 93b5636ba43bcd907c34ba61fcc00aba47349597 |
| Indexer-Queue | `community.opengroup.org:5555/osdu/platform/system/indexer-queue/indexer-queue-master` | 4b56366f90f2fb6ba904ab9ba672a0595e9a6a4b |
| Indexer       | `community.opengroup.org:5555/osdu/platform/system/indexer-service/indexer-service-master` | f0699e2af5e96eb1e853d6785f9abe97e87ba39d |
| Search        | `community.opengroup.org:5555/osdu/platform/system/search-service/search-service-master` | c42afcb11c0b36229cc2b2803f4e15958232d95a |
| Delivery      | `community.opengroup.org:5555/osdu/platform/system/delivery/delivery-master` | 16a935048c6e9ace219d08fd3feb718a4b1d7abf |
| File          | `community.opengroup.org:5555/osdu/platform/system/file/file-master` | 1144aa06e6b70df8e1c06ccc6331cb78a79951cc |


__Infrastructure Support__

- Airflow

__Devops Support__

- Airflow
- Python Testing Tasks

__Chart Support__

- osdu-airflow

__New Services__

- [Delivery](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/issues/21)
- [File](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/issues/40)