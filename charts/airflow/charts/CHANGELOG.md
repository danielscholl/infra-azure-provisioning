# CHANGELOG

## [90cdb1bc1597f74b34ec2a2fd369b460d9fc3251](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/commit/90cdb1bc1597f74b34ec2a2fd369b460d9fc3251)

- Fixed graceful termination script in `templates/configmap-scripts.yaml` under `graceful-stop-celery-worker.sh` where the `celery inspect` command is wrapped with `$()` to avoid syntax error if redis password contains special characters
