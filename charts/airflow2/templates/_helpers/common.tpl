{{/*
Construct the base name for all resources in this chart.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osdu.airflow.fullname" -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Construct the `labels.app` for used by all resources in this chart.
*/}}
{{- define "osdu.airflow.labels.app" -}}
{{- printf "%s" .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
A flag indicating if a celery-like executor is selected (empty if false)
*/}}
{{- define "osdu.airflow.executor.celery_like" -}}
{{- if or (eq .Values.airflow.airflow.executor "CeleryExecutor") (eq .Values.airflow.airflow.executor "CeleryKubernetesExecutor") -}}
true
{{- end -}}
{{- end -}}

{{/*
A flag indicating if a kubernetes-like executor is selected (empty if false)
*/}}
{{- define "osdu.airflow.executor.kubernetes_like" -}}
{{- if or (eq .Values.airflow.airflow.executor "KubernetesExecutor") (eq .Values.airflow.airflow.executor "CeleryKubernetesExecutor") -}}
true
{{- end -}}
{{- end -}}

{{/*
The scheme (HTTP, HTTPS) used by the webserver
*/}}
{{- define "osdu.airflow.web.scheme" -}}
{{- if and (.Values.airflow.airflow.config.AIRFLOW__WEBSERVER__WEB_SERVER_SSL_CERT) (.Values.airflow.airflow.config.AIRFLOW__WEBSERVER__WEB_SERVER_SSL_KEY) -}}
HTTPS
{{- else -}}
HTTP
{{- end -}}
{{- end -}}

{{/*
The path containing DAG files
*/}}
{{- define "osdu.airflow.dags.path" -}}
{{- if .Values.airflow.dags.gitSync.enabled -}}
{{- printf "%s/repo/%s" (.Values.airflow.dags.path | trimSuffix "/") (.Values.airflow.dags.gitSync.repoSubPath | trimAll "/") -}}
{{- else -}}
{{- printf .Values.airflow.dags.path -}}
{{- end -}}
{{- end -}}

{{/*
If PgBouncer should be used.
*/}}
{{- define "osdu.airflow.pgbouncer.should_use" -}}
{{- if .Values.airflow.pgbouncer.enabled -}}
{{- if or (.Values.airflow.postgresql.enabled) (eq .Values.airflow.externalDatabase.type "postgres") -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Construct the `postgresql.fullname` of the postgresql sub-chat chart.
Used to discover the Service and Secret name created by the sub-chart.
*/}}
{{- define "osdu.airflow.postgresql.fullname" -}}
{{- if .Values.airflow.postgresql.fullnameOverride -}}
{{- .Values.airflow.postgresql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "postgresql" .Values.airflow.postgresql.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Construct the `redis.fullname` of the redis sub-chat chart.
Used to discover the master Service and Secret name created by the sub-chart.
*/}}
{{- define "osdu.airflow.redis.fullname" -}}
{{- if .Values.airflow.redis.fullnameOverride -}}
{{- .Values.airflow.redis.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "redis" .Values.airflow.redis.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}
