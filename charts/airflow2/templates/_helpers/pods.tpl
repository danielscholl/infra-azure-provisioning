{{/*
Define the image configs for airflow containers
*/}}
{{- define "osdu.airflow.image" }}
image: {{ .Values.airflow.airflow.image.repository }}:{{ .Values.airflow.airflow.image.tag }}
imagePullPolicy: {{ .Values.airflow.airflow.image.pullPolicy }}
securityContext:
  runAsUser: {{ .Values.airflow.airflow.image.uid }}
  runAsGroup: {{ .Values.airflow.airflow.image.gid }}
{{- end }}

{{/*
Define the command/entrypoint configs for airflow containers
*/}}
{{- define "osdu.airflow.command" }}
- "/usr/bin/dumb-init"
- "--"
{{- /* only use `/entrypoint` for airflow 2.0+ (older images dont pass "bash" & "python") */ -}}
{{- if not .Values.airflow.airflow.legacyCommands }}
- "/entrypoint"
{{- end }}
{{- end }}

{{/*
Define the nodeSelector for airflow pods
EXAMPLE USAGE: {{ include "osdu.airflow.nodeSelector" (dict "Release" .Release "Values" .Values.airflow "nodeSelector" $nodeSelector) }}
*/}}
{{- define "osdu.airflow.podNodeSelector" }}
{{- .nodeSelector | default .Values.airflow.airflow.defaultNodeSelector | toYaml }}
{{- end }}

{{/*
Define the Affinity for airflow pods
EXAMPLE USAGE: {{ include "osdu.airflow.podAffinity" (dict "Release" .Release "Values" .Values.airflow "affinity" $affinity) }}
*/}}
{{- define "osdu.airflow.podAffinity" }}
{{- .affinity | default .Values.airflow.airflow.defaultAffinity | toYaml }}
{{- end }}

{{/*
Define the Tolerations for airflow pods
EXAMPLE USAGE: {{ include "osdu.airflow.podTolerations" (dict "Release" .Release "Values" .Values.airflow "tolerations" $tolerations) }}
*/}}
{{- define "osdu.airflow.podTolerations" }}
{{- .tolerations | default .Values.airflow.airflow.defaultTolerations | toYaml }}
{{- end }}

{{/*
Define the PodSecurityContext for airflow pods
EXAMPLE USAGE: {{ include "osdu.airflow.podSecurityContext" (dict "Release" .Release "Values" .Values.airflow "securityContext" $securityContext) }}
*/}}
{{- define "osdu.airflow.podSecurityContext" }}
{{- .securityContext | default .Values.airflow.airflow.defaultSecurityContext | toYaml }}
{{- end }}

{{/*
Define an init-container which checks the DB status
EXAMPLE USAGE: {{ include "osdu.airflow.init_container.check_db" (dict "Release" .Release "Values" .Values.airflow "volumeMounts" $volumeMounts) }}
*/}}
{{- define "osdu.airflow.init_container.check_db" }}
- name: check-db
  {{- include "osdu.airflow.image" . | indent 2 }}
  envFrom:
    {{- include "osdu.airflow.envFrom" . | indent 4 }}
  env:
    {{- include "osdu.airflow.env" . | indent 4 }}
  command:
    {{- include "osdu.airflow.command" . | indent 4 }}
  args:
    - "bash"
    - "-c"
    {{- if .Values.airflow.airflow.legacyCommands }}
    - "exec timeout 60s airflow checkdb"
    {{- else }}
    - "exec timeout 60s airflow db check"
    {{- end }}
  {{- if .volumeMounts }}
  volumeMounts:
    {{- .volumeMounts | indent 4 }}
  {{- end }}
{{- end }}

{{/*
Define an init-container which waits for DB migrations
EXAMPLE USAGE: {{ include "osdu.airflow.init_container.wait_for_db_migrations" (dict "Release" .Release "Values" .Values.airflow "volumeMounts" $volumeMounts) }}
*/}}
{{- define "osdu.airflow.init_container.wait_for_db_migrations" }}
- name: wait-for-db-migrations
  {{- include "osdu.airflow.image" . | indent 2 }}
  envFrom:
    {{- include "osdu.airflow.envFrom" . | indent 4 }}
  env:
    {{- include "osdu.airflow.env" . | indent 4 }}
  command:
    {{- include "osdu.airflow.command" . | indent 4 }}
  args:
    {{- if .Values.airflow.airflow.legacyCommands }}
    - "python"
    - "-c"
    - |
      import logging
      import os
      import time

      import airflow
      from airflow import settings

      # modified from https://github.com/apache/airflow/blob/2.1.0/airflow/utils/db.py#L583-L592
      def _get_alembic_config():
          from alembic.config import Config

          package_dir = os.path.abspath(os.path.dirname(airflow.__file__))
          directory = os.path.join(package_dir, 'migrations')
          config = Config(os.path.join(package_dir, 'alembic.ini'))
          config.set_main_option('script_location', directory.replace('%', '%%'))
          config.set_main_option('sqlalchemy.url', settings.SQL_ALCHEMY_CONN.replace('%', '%%'))
          return config

      # copied from https://github.com/apache/airflow/blob/2.1.0/airflow/utils/db.py#L595-L622
      def check_migrations(timeout):
          """
          Function to wait for all airflow migrations to complete.
          :param timeout: Timeout for the migration in seconds
          :return: None
          """
          from alembic.runtime.migration import MigrationContext
          from alembic.script import ScriptDirectory

          config = _get_alembic_config()
          script_ = ScriptDirectory.from_config(config)
          with settings.engine.connect() as connection:
              context = MigrationContext.configure(connection)
              ticker = 0
              while True:
                  source_heads = set(script_.get_heads())
                  db_heads = set(context.get_current_heads())
                  if source_heads == db_heads:
                      break
                  if ticker >= timeout:
                      raise TimeoutError(
                          f"There are still unapplied migrations after {ticker} seconds. "
                          f"Migration Head(s) in DB: {db_heads} | Migration Head(s) in Source Code: {source_heads}"
                      )
                  ticker += 1
                  time.sleep(1)
                  logging.info('Waiting for migrations... %s second(s)', ticker)

      check_migrations(60)
    {{- else }}
    - "bash"
    - "-c"
    - "exec airflow db check-migrations -t 60"
    {{- end }}
  {{- if .volumeMounts }}
  volumeMounts:
    {{- .volumeMounts | indent 4 }}
  {{- end }}
{{- end }}

{{/*
Define an init-container which installs a list of pip packages
EXAMPLE USAGE: {{ include "osdu.airflow.init_container.install_pip_packages" (dict "Release" .Release "Values" .Values.airflow "extraPipPackages" $extraPipPackages) }}
*/}}
{{- define "osdu.airflow.init_container.install_pip_packages" }}
- name: install-pip-packages
  {{- include "osdu.airflow.image" . | indent 2 }}
  envFrom:
    {{- include "osdu.airflow.envFrom" . | indent 4 }}
  env:
    {{- include "osdu.airflow.env" . | indent 4 }}
  command:
    {{- include "osdu.airflow.command" . | indent 4 }}
  args:
    - "bash"
    - "-c"
    - |
      unset PYTHONUSERBASE && \
      pip install --user {{ range .extraPipPackages }}{{ . | quote }} {{ end }} && \
      echo "copying '/home/airflow/.local/*' to '/opt/home-airflow-local'..." && \
      cp -r /home/airflow/.local/* /opt/home-airflow-local
  volumeMounts:
    - name: home-airflow-local
      mountPath: /opt/home-airflow-local
{{- end }}

{{/*
Define a container which regularly syncs a git-repo
EXAMPLE USAGE: {{ include "osdu.airflow.container.git_sync" (dict "Release" .Release "Values" .Values.airflow "sync_one_time" "true") }}
*/}}
{{- define "osdu.airflow.container.git_sync" }}
{{- if .sync_one_time }}
- name: dags-git-clone
{{- else }}
- name: dags-git-sync
{{- end }}
  image: {{ .Values.airflow.dags.gitSync.image.repository }}:{{ .Values.airflow.dags.gitSync.image.tag }}
  imagePullPolicy: {{ .Values.airflow.dags.gitSync.image.pullPolicy }}
  securityContext:
    runAsUser: {{ .Values.airflow.dags.gitSync.image.uid }}
    runAsGroup: {{ .Values.airflow.dags.gitSync.image.gid }}
  resources:
    {{- toYaml .Values.airflow.dags.gitSync.resources | nindent 4 }}
  envFrom:
    {{- include "osdu.airflow.envFrom" . | indent 4 }}
  env:
    {{- if .sync_one_time }}
    - name: GIT_SYNC_ONE_TIME
      value: "true"
    {{- end }}
    - name: GIT_SYNC_ROOT
      value: "/dags"
    - name: GIT_SYNC_DEST
      value: "repo"
    - name: GIT_SYNC_REPO
      value: {{ .Values.airflow.dags.gitSync.repo | quote }}
    - name: GIT_SYNC_BRANCH
      value: {{ .Values.airflow.dags.gitSync.branch | quote }}
    - name: GIT_SYNC_REV
      value: {{ .Values.airflow.dags.gitSync.revision | quote }}
    - name: GIT_SYNC_DEPTH
      value: {{ .Values.airflow.dags.gitSync.depth | quote }}
    - name: GIT_SYNC_WAIT
      value: {{ .Values.airflow.dags.gitSync.syncWait | quote }}
    - name: GIT_SYNC_TIMEOUT
      value: {{ .Values.airflow.dags.gitSync.syncTimeout | quote }}
    - name: GIT_SYNC_ADD_USER
      value: "true"
    - name: GIT_SYNC_MAX_FAILURES
      value: {{ .Values.airflow.dags.gitSync.maxFailures | quote }}
    {{- if .Values.airflow.dags.gitSync.sshSecret }}
    - name: GIT_SYNC_SSH
      value: "true"
    - name: GIT_SSH_KEY_FILE
      value: "/etc/git-secret/id_rsa"
    {{- end }}
    {{- if .Values.airflow.dags.gitSync.sshKnownHosts }}
    - name: GIT_KNOWN_HOSTS
      value: "true"
    - name: GIT_SSH_KNOWN_HOSTS_FILE
      value: "/etc/git-secret/known_hosts"
    {{- else }}
    - name: GIT_KNOWN_HOSTS
      value: "false"
    {{- end }}
    {{- if .Values.airflow.dags.gitSync.httpSecret }}
    - name: GIT_SYNC_USERNAME
      valueFrom:
        secretKeyRef:
          name: {{ .Values.airflow.dags.gitSync.httpSecret }}
          key: {{ .Values.airflow.dags.gitSync.httpSecretUsernameKey }}
    - name: GIT_SYNC_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ .Values.airflow.dags.gitSync.httpSecret }}
          key: {{ .Values.airflow.dags.gitSync.httpSecretPasswordKey }}
    {{- end }}
    {{- /* this has user-defined variables, so must be included BELOW (so the ABOVE `env` take precedence) */ -}}
    {{- include "osdu.airflow.env" . | indent 4 }}
  volumeMounts:
    - name: dags-data
      mountPath: /dags
    {{- if .Values.airflow.dags.gitSync.sshSecret }}
    - name: git-secret
      mountPath: /etc/git-secret/id_rsa
      readOnly: true
      subPath: {{ .Values.airflow.dags.gitSync.sshSecretKey }}
    {{- end }}
    {{- if .Values.airflow.dags.gitSync.sshKnownHosts }}
    - name: git-known-hosts
      mountPath: /etc/git-secret/known_hosts
      readOnly: true
      subPath: known_hosts
    {{- end }}
{{- end }}

{{/*
The list of `volumeMounts` for web/scheduler/worker/flower container
EXAMPLE USAGE: {{ include "osdu.airflow.volumeMounts" (dict "Release" .Release "Values" .Values.airflow "extraPipPackages" $extraPipPackages "extraVolumeMounts" $extraVolumeMounts) }}
*/}}
{{- define "osdu.airflow.volumeMounts" }}
{{- /* airflow_local_settings.py */ -}}
{{- if or (.Values.airflow.airflow.localSettings.stringOverride) (.Values.airflow.airflow.localSettings.existingSecret) }}
- name: airflow-local-settings
  mountPath: /opt/airflow/config/airflow_local_settings.py
  subPath: airflow_local_settings.py
  readOnly: true
{{- end }}

{{- /* dags */ -}}
{{- if .Values.airflow.dags.persistence.enabled }}
- name: dags-data
  mountPath: {{ .Values.airflow.dags.path }}
  subPath: {{ .Values.airflow.dags.persistence.subPath }}
  {{- if eq .Values.airflow.dags.persistence.accessMode "ReadOnlyMany" }}
  readOnly: true
  {{- end }}
{{- else if .Values.airflow.dags.gitSync.enabled }}
- name: dags-data
  mountPath: {{ .Values.airflow.dags.path }}
{{- end }}

{{- /* logs */ -}}
{{- if .Values.airflow.logs.persistence.enabled }}
- name: logs-data
  mountPath: {{ .Values.airflow.logs.path }}
  subPath: {{ .Values.airflow.logs.persistence.subPath }}
{{- end }}

{{- /* pip-packages */ -}}
{{- if .extraPipPackages }}
- name: home-airflow-local
  mountPath: /home/airflow/.local
{{- end }}

{{- /* user-defined (global) */ -}}
{{- if .Values.airflow.airflow.extraVolumeMounts }}
{{ toYaml .Values.airflow.airflow.extraVolumeMounts }}
{{- end }}

{{- /* user-defined */ -}}
{{- if .extraVolumeMounts }}
{{ toYaml .extraVolumeMounts }}
{{- end }}
{{- end }}

{{/*
The list of `envFrom` for web/scheduler/worker/flower Pods
*/}}
{{- define "osdu.airflow.envFrom" }}
- secretRef:
    name: {{ include "osdu.airflow.fullname" . }}-config-envs
{{- end }}

{{/*
The list of `env` for web/scheduler/worker/flower Pods
*/}}
{{- define "osdu.airflow.env" }}
{{- /* postgres environment variables */ -}}
{{- if .Values.airflow.postgresql.enabled }}
{{- if .Values.airflow.postgresql.existingSecret }}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.airflow.postgresql.existingSecret }}
      key: {{ .Values.airflow.postgresql.existingSecretKey }}
{{- else }}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "osdu.airflow.postgresql.fullname" . }}
      key: postgresql-password
{{- end }}
{{- else }}
{{- if .Values.airflow.externalDatabase.passwordSecret }}
- name: DATABASE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.airflow.externalDatabase.passwordSecret }}
      key: {{ .Values.airflow.externalDatabase.passwordSecretKey }}
{{- else }}
- name: DATABASE_PASSWORD
  value: ""
{{- end }}
{{- end }}

{{- /* redis environment variables */ -}}
{{- if .Values.airflow.redis.enabled }}
{{- if .Values.airflow.redis.existingSecret }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.airflow.redis.existingSecret }}
      key: {{ .Values.airflow.redis.existingSecretPasswordKey }}
{{- else }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "osdu.airflow.redis.fullname" . }}
      key: redis-password
{{- end }}
{{- else }}
{{- if .Values.airflow.externalRedis.passwordSecret }}
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.airflow.externalRedis.passwordSecret }}
      key: {{ .Values.airflow.externalRedis.passwordSecretKey }}
{{- else }}
- name: REDIS_PASSWORD
  value: ""
{{- end }}
{{- end }}

{{- /* disable the `/entrypoint` db connection check */ -}}
{{- if not .Values.airflow.airflow.legacyCommands }}
- name: CONNECTION_CHECK_MAX_COUNT
  value: "0"
{{- end }}

{{- /* set AIRFLOW__CELERY__FLOWER_BASIC_AUTH */ -}}
{{- if .Values.airflow.flower.basicAuthSecret }}
- name: AIRFLOW__CELERY__FLOWER_BASIC_AUTH
  valueFrom:
    secretKeyRef:
      name: {{ .Values.airflow.flower.basicAuthSecret }}
      key: {{ .Values.airflow.flower.basicAuthSecretKey }}
{{- end }}

{{- /* user-defined environment variables */ -}}
{{- if .Values.airflow.airflow.extraEnv }}
{{ toYaml .Values.airflow.airflow.extraEnv }}
{{- end }}
{{- end }}
