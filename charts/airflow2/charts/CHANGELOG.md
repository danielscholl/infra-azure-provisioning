# CHANGELOG

## AKS Security policies for airflow2

Tracking this issue in airflow-community. [ISSUE](https://github.com/airflow-helm/charts/issues/578)

__Actual Code__ To enable `allowPrivilegeEscalation` option in the values.

```yaml
{{- define "airflow.image" }}
image: {{ .Values.airflow.image.repository }}:{{ .Values.airflow.image.tag }}
imagePullPolicy: {{ .Values.airflow.image.pullPolicy }}
securityContext:
  runAsUser: {{ .Values.airflow.image.uid }}
  runAsGroup: {{ .Values.airflow.image.gid }}
{{- range $key, $value := .Values.airflow.containerSecurityContext }}
  {{- if and (not (eq $key "runAsUser")) (not (eq $key "runAsGroup")) }}
  {{ $key }}: {{ $value }} 
  {{- end }}
{{- end }}
{{- end }}
```

__Original Code__: [airflow-8.5.2](https://github.com/airflow-helm/charts/blob/airflow-8.5.2/charts/airflow/templates/_helpers/pods.tpl#L7)

Unfortunately the `containerSecurityContext` cannot be modified in the community helm chart, we even tried with the `Values.DefaultSecurityContext`, nevertheless, does not have good outcome that way, If we plan to add the `allowPrivilegeEscalation: false` in `podSecurityContext`, will see errors while deploying helm chart.

[Full discussion MR278](https://community.opengroup.org/osdu/platform/deployment-and-operations/helm-charts-azure/-/merge_requests/278)

In the [values.yaml](../values.yaml), we need to add the following to comply with policy:

```yaml
airflow:
  airflow:
    containerSecurityContext:
      allowPrivilegeEscalation: false
      # runAsUser and runAsGroup will not be noted
```

## [90cdb1bc1597f74b34ec2a2fd369b460d9fc3251](https://community.opengroup.org/osdu/platform/deployment-and-operations/infra-azure-provisioning/-/commit/90cdb1bc1597f74b34ec2a2fd369b460d9fc3251)

- Fixed graceful termination script in `templates/configmap-scripts.yaml` under `graceful-stop-celery-worker.sh` where the `celery inspect` command is wrapped with `$()` to avoid syntax error if redis password contains special characters

Below is the change in `templates/configmap-scripts.yaml` under `graceful-stop-celery-worker.sh` 

**Actual code**
```bash
    while (( celery inspect --broker $AIRFLOW__CELERY__BROKER_URL --destination celery@$HOSTNAME --json active | python3 -c "import json;     active_tasks = json.loads(input())['celery@$HOSTNAME']; print(len(active_tasks))" > 0 )); do
      sleep 10
    done
```

**Changed code**
```bash
    while (( $(celery inspect --broker $AIRFLOW__CELERY__BROKER_URL --destination celery@$HOSTNAME --json active | python3 -c "import json; active_tasks = json.loads(input())['celery@$HOSTNAME']; print(len(active_tasks))") > 0 )); do
      sleep 10
    done
```