---
global:
  image:
    # -- Overrides the Docker registry globally for all images
    registry: null
  # -- Overrides the priorityClassName for all pods
  priorityClassName: null
  # -- configures cluster domain ("cluster.local" by default)
  clusterDomain: "cluster.local"
  # -- configures DNS service name
  dnsService: "kube-dns"
  # -- configures DNS service namespace
  dnsNamespace: "kube-system"

# -- Overrides the chart's name
nameOverride: null

# -- Overrides the chart's computed fullname
fullnameOverride: null

# -- Image pull secrets for Docker images
imagePullSecrets: []

loki:
  # Configures the readiness probe for all of the Loki pods
  readinessProbe:
    httpGet:
      path: /ready
      port: http-metrics
    initialDelaySeconds: 30
    timeoutSeconds: 1
  image:
    # -- The Docker registry
    registry: docker.io
    # -- Docker image repository
    repository: grafana/loki
    # -- Overrides the image tag whose default is the chart's appVersion
    tag: null
    # -- Docker image pull policy
    pullPolicy: IfNotPresent
  # -- Common annotations for all pods
  podAnnotations: {}
  # -- The number of old ReplicaSets to retain to allow rollback
  revisionHistoryLimit: 10
  # -- The SecurityContext for Loki pods
  podSecurityContext:
    fsGroup: 10001
    runAsGroup: 10001
    runAsNonRoot: true
    runAsUser: 10001
  # -- The SecurityContext for Loki containers
  containerSecurityContext:
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL
    allowPrivilegeEscalation: false
  # -- Specify an existing secret containing loki configuration. If non-empty, overrides `loki.config`
  existingSecretForConfig: ""
  # -- Config file contents for Loki
  # @default -- See values.yaml
  config: |
    {{- if .Values.enterprise.enabled}}
    {{- tpl .Values.enterprise.config . }}
    {{- else }}
    auth_enabled: {{ .Values.loki.auth_enabled }}
    {{- end }}

    server:
      http_listen_port: 3100
      grpc_listen_port: 9095

    memberlist:
      join_members:
        - {{ include "loki.name" . }}-memberlist

    {{- if .Values.loki.commonConfig}}
    common:
    {{- toYaml .Values.loki.commonConfig | nindent 2}}
      storage:
      {{- include "loki.commonStorageConfig" . | nindent 4}}
    {{- end}}

    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h
      max_cache_freshness_per_query: 10m
      split_queries_by_interval: 15m

    {{- with .Values.loki.memcached.chunk_cache }}
    {{- if and .enabled .host }}
    chunk_store_config:
      chunk_cache_config:
        memcached:
          batch_size: {{ .batch_size }}
          parallelism: {{ .parallelism }}
        memcached_client:
          host: {{ .host }}
          service: {{ .service }}
    {{- end }}
    {{- end }}

    {{- if .Values.loki.schemaConfig}}
    schema_config:
    {{- toYaml .Values.loki.schemaConfig | nindent 2}}
    {{- else }}
    schema_config:
      configs:
        - from: 2022-01-11
          store: boltdb-shipper
          {{- if eq .Values.loki.storage.type "s3" }}
          object_store: s3
          {{- else if eq .Values.loki.storage.type "gcs" }}
          object_store: gcs
          {{- else }}
          object_store: filesystem
          {{- end }}
          schema: v12
          index:
            prefix: loki_index_
            period: 24h
    {{- end }}

    {{- if or .Values.minio.enabled (eq .Values.loki.storage.type "s3") (eq .Values.loki.storage.type "gcs") }}
    ruler:
      storage:
      {{- include "loki.rulerStorageConfig" . | nindent 4}}
    {{- end -}}

    {{- with .Values.loki.memcached.results_cache }}
    query_range:
      align_queries_with_step: true
      {{- if and .enabled .host }}
      cache_results: {{ .enabled }}
      results_cache:
        cache:
          default_validity: {{ .default_validity }}
          memcached_client:
            host: {{ .host }}
            service: {{ .service }}
            timeout: {{ .timeout }}
      {{- end }}
    {{- end }}

    {{- with .Values.loki.storage_config }}
    storage_config:
      {{- tpl (. | toYaml) $ | nindent 4 }}
    {{- end }}

    {{- with .Values.loki.query_scheduler }}
    query_scheduler:
      {{- tpl (. | toYaml) $ | nindent 4 }}
    {{- end }}

  # Should authentication be enabled
  auth_enabled: false

  # -- Check https://grafana.com/docs/loki/latest/configuration/#common_config for more info on how to provide a common configuration
  commonConfig:
    path_prefix: /var/loki
    replication_factor: 3

  storage:
    bucketNames:
      chunks: chunks
      ruler: ruler
      admin: admin
    type: s3
    s3:
      s3: null
      endpoint: null
      region: null
      secretAccessKey: null
      accessKeyId: null
      s3ForcePathStyle: false
      insecure: false
    gcs:
      chunkBufferSize: 0
      requestTimeout: "0s"
      enableHttp2: true
    local:
      chunks_directory: /var/loki/chunks
      rules_directory: /var/loki/rules

  # -- Configure memcached as an external cache for chunk and results cache. Disabled by default
  # must enable and specify a host for each cache you would like to use.
  memcached:
    chunk_cache:
      enabled: false
      host: ""
      service: "memcached-client"
      batch_size: 256
      parallelism: 10
    results_cache:
      enabled: false
      host: ""
      service: "memcached-client"
      timeout: "500ms"
      default_validity: "12h"

  # -- Check https://grafana.com/docs/loki/latest/configuration/#schema_config for more info on how to configure schemas
  schemaConfig: {}

  # -- Structured loki configuration, takes precedence over `loki.config`, `loki.schemaConfig`, `loki.storageConfig`
  structuredConfig: {}

  # -- Additional query scheduler config
  query_scheduler: {}

  # -- Additional storage config
  storage_config:
    hedging:
      at: "250ms"
      max_per_second: 20
      up_to: 3

enterprise:
  # Enable enterprise features, license must be provided
  enabled: false

  # Default verion of GEL to deploy
  version: v1.5.0

  # -- Grafana Enterprise Logs license
  # In order to use Grafana Enterprise Logs features, you will need to provide
  # the contents of your Grafana Enterprise Logs license, either by providing the
  # contents of the license.jwt, or the name Kubernetes Secret that contains your
  # license.jwt.
  # To set the license contents, use the flag `--set-file 'license.contents=./license.jwt'`
  license:
    contents: "NOTAVALIDLICENSE"

  # -- Set to true when providing an external license
  useExternalLicense: false

  # -- Name of external licesne secret to use
  externalLicenseName: null

  # -- If enabled, the correct admin_client storage will be configured. If disabled while running enterprise,
  # make sure auth is set to `type: trust`, or that `auth_enabled` is set to `false`.
  adminApi:
    enabled: true

  # enterprise specific sections of the config.yaml file
  config: |
    {{- if .Values.enterprise.adminApi.enabled }}
    {{- if or .Values.minio.enabled (eq .Values.loki.storage.type "s3") (eq .Values.loki.storage.type "gcs") }}
    admin_client:
      storage:
        s3:
          bucket_name: {{ .Values.loki.storage.bucketNames.admin }}
    {{- end }}
    {{- end }}
    auth:
      type: {{ .Values.enterprise.adminApi.enabled | ternary "enterprise" "trust" }}
    auth_enabled: {{ .Values.loki.auth_enabled }}
    cluster_name: {{ .Release.Name }}
    license:
      path: /etc/loki/license/license.jwt

  image:
    # -- The Docker registry
    registry: docker.io
    # -- Docker image repository
    repository: grafana/enterprise-logs
    # -- Overrides the image tag whose default is the chart's appVersion
    tag: v1.4.0
    # -- Docker image pull policy
    pullPolicy: IfNotPresent

  # -- Configuration for `tokengen` target
  tokengen:
    # -- Whether the job should be part of the deployment
    enabled: true
    # -- Name of the secret to store the admin token in
    adminTokenSecret: "gel-admin-token"
    # -- Additional CLI arguments for the `tokengen` target
    extraArgs: []
    # -- Additional Kubernetes environment
    env: []
    # -- Additional labels for the `tokengen` Job
    labels: {}
    # -- Additional annotations for the `tokengen` Job
    annotations: {}
    # -- Additional volumes for Pods
    extraVolumes: []
    # -- Additional volume mounts for Pods
    extraVolumeMounts: []
    # -- Run containers as user `enterprise-logs(uid=10001)`
    securityContext:
      runAsNonRoot: true
      runAsGroup: 10001
      runAsUser: 10001
      fsGroup: 10001

  nginxConfig:
    file: |
      worker_processes  5;  ## Default: 1
      error_log  /dev/stderr;
      pid        /tmp/nginx.pid;
      worker_rlimit_nofile 8192;

      events {
        worker_connections  4096;  ## Default: 1024
      }

      http {
        client_body_temp_path /tmp/client_temp;
        proxy_temp_path       /tmp/proxy_temp_path;
        fastcgi_temp_path     /tmp/fastcgi_temp;
        uwsgi_temp_path       /tmp/uwsgi_temp;
        scgi_temp_path        /tmp/scgi_temp;

        proxy_http_version    1.1;

        default_type application/octet-stream;
        log_format   {{ .Values.gateway.nginxConfig.logFormat }}

        {{- if .Values.gateway.verboseLogging }}
        access_log   /dev/stderr  main;
        {{- else }}

        map $status $loggable {
          ~^[23]  0;
          default 1;
        }
        access_log   /dev/stderr  main  if=$loggable;
        {{- end }}

        sendfile     on;
        tcp_nopush   on;
        resolver {{ .Values.global.dnsService }}.{{ .Values.global.dnsNamespace }}.svc.{{ .Values.global.clusterDomain }};

        {{- with .Values.gateway.nginxConfig.httpSnippet }}
        {{ . | nindent 2 }}
        {{- end }}

        server {
          listen             8080;

          {{- if .Values.gateway.basicAuth.enabled }}
          auth_basic           "Loki";
          auth_basic_user_file /etc/nginx/secrets/.htpasswd;
          {{- end }}

          location = / {
            return 200 'OK';
            auth_basic off;
          }

          location = /api/prom/push {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /api/prom/tail {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          }

          location ~ /api/prom/.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /prometheus/api/v1/alerts.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /prometheus/api/v1/rules.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /loki/api/v1/push {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /loki/api/v1/tail {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          }

          location ~ /loki/api/.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /admin/api/.* {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /compactor/.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /distributor/.* {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /ring {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /ingester/.* {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /ruler/.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location ~ /scheduler/.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          {{- with .Values.gateway.nginxConfig.serverSnippet }}
          {{ . | nindent 4 }}
          {{- end }}
        }
      }

serviceAccount:
  # -- Specifies whether a ServiceAccount should be created
  create: true
  # -- The name of the ServiceAccount to use.
  # If not set and create is true, a name is generated using the fullname template
  name: null
  # -- Image pull secrets for the service account
  imagePullSecrets: []
  # -- Annotations for the service account
  annotations: {}
  # -- Set this toggle to false to opt out of automounting API credentials for the service account
  automountServiceAccountToken: true

# RBAC configuration
rbac:
  # -- If pspEnabled true, a PodSecurityPolicy is created for K8s that use psp.
  pspEnabled: false
  # -- For OpenShift set pspEnabled to 'false' and sccEnabled to 'true' to use the SecurityContextConstraints.
  sccEnabled: false

# Monitoring section determines which monitoring features to enable
monitoring:
  # Dashboards for monitoring Loki
  dashboards:
    # -- If enabled, create configmap with dashboards for monitoring Loki
    enabled: true
    # -- Alternative namespace to create dashboards ConfigMap in
    namespace: null
    # -- Additional annotations for the dashboards ConfigMap
    annotations: {}
    # -- Additional labels for the dashboards ConfigMap
    labels: {}

  # Recording rules for monitoring Loki, required for some dashboards
  rules:
    # -- If enabled, create PrometheusRule resource with Loki recording rules
    enabled: true
    # -- Include alerting rules
    alerting: true
    # -- Alternative namespace to create recording rules PrometheusRule resource in
    namespace: null
    # -- Additional annotations for the rules PrometheusRule resource
    annotations: {}
    # -- Additional labels for the rules PrometheusRule resource
    labels: {}
    # -- Additional groups to add to the rules file
    additionalGroups: []
    # - name: additional-loki-rules
    #   rules:
    #     - record: job:loki_request_duration_seconds_bucket:sum_rate
    #       expr: sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job)
    #     - record: job_route:loki_request_duration_seconds_bucket:sum_rate
    #       expr: sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route)
    #     - record: node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate
    #       expr: sum(rate(container_cpu_usage_seconds_total[1m])) by (node, namespace, pod, container)

  # Alerting rules for monitoring Loki
  alerts:
    # -- If enabled, create PrometheusRule resource with Loki alerting rules
    enabled: true
    # -- Alternative namespace to create alerting rules PrometheusRule resource in
    namespace: null
    # -- Additional annotations for the alerts PrometheusRule resource
    annotations: {}
    # -- Additional labels for the alerts PrometheusRule resource
    labels: {}

  # ServiceMonitor configuration
  serviceMonitor:
    # -- If enabled, ServiceMonitor resources for Prometheus Operator are created
    enabled: true
    # -- Alternative namespace for ServiceMonitor resources
    namespace: null
    # -- Namespace selector for ServiceMonitor resources
    namespaceSelector: {}
    # -- ServiceMonitor annotations
    annotations: {}
    # -- Additional ServiceMonitor labels
    labels: {}
    # -- ServiceMonitor scrape interval
    interval: null
    # -- ServiceMonitor scrape timeout in Go duration format (e.g. 15s)
    scrapeTimeout: null
    # -- ServiceMonitor relabel configs to apply to samples before scraping
    # https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/api.md#relabelconfig
    relabelings: []
    # -- ServiceMonitor will use http by default, but you can pick https as well
    scheme: http
    # -- ServiceMonitor will use these tlsConfig settings to make the health check requests
    tlsConfig: null

  # Self monitoring determines whether Loki should scrape it's own logs.
  # This feature currently relies on the Grafana Agent Operator being installed,
  # which is installed by default using the grafana-agent-operator sub-chart.
  # It will create custom resources for GrafanaAgent, LogsInstance, and PodLogs to configure
  # scrape configs to scrape it's own logs with the labels expected by the included dashboards.
  selfMonitoring:
    enabled: false

    # Grafana Agent configuration
    grafanaAgent:
      # -- Controls whether to install the Grafana Agent Operator and its CRDs.
      # Note that helm will not install CRDs if this flag is enabled during an upgrade.
      # In that case install the CRDs manually from https://github.com/grafana/agent/tree/main/production/operator/crds
      installOperator: false
      # -- Alternative namespace for Grafana Agent resources
      namespace: null
      # -- Grafana Agent annotations
      annotations: {}
      # -- Additional Grafana Agent labels
      labels: {}
      # -- Enable the config read api on port 8080 of the agent
      enableConfigReadAPI: false

    # PodLogs configuration
    podLogs:
      # -- Alternative namespace for PodLogs resources
      namespace: null
      # -- PodLogs annotations
      annotations: {}
      # -- Additional PodLogs labels
      labels: {}
      # -- PodLogs relabel configs to apply to samples before scraping
      # https://github.com/prometheus-operator/prometheus-operator/blob/master/Documentation/api.md#relabelconfig
      relabelings: []

    # LogsInstance configuration
    logsInstance:
      # -- Alternative namespace for LogsInstance resources
      namespace: null
      # -- LogsInstance annotations
      annotations: {}
      # -- Additional LogsInstance labels
      labels: {}

# Configuration for the write
write:
  # -- Number of replicas for the write
  replicas: 3
  image:
    # -- The Docker registry for the write image. Overrides `loki.image.registry`
    registry: null
    # -- Docker image repository for the write image. Overrides `loki.image.repository`
    repository: null
    # -- Docker image tag for the write image. Overrides `loki.image.tag`
    tag: null
  # -- The name of the PriorityClass for write pods
  priorityClassName: null
  # -- Annotations for write pods
  podAnnotations: {}
  # -- Additional selector labels for each `write` pod
  selectorLabels: {}
  # -- Labels for ingestor service
  serviceLabels: {}
  # -- Additional CLI args for the write
  extraArgs: []
  # -- Environment variables to add to the write pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the write pods
  extraEnvFrom: []
  # -- Volume mounts to add to the write pods
  extraVolumeMounts: []
  # -- Volumes to add to the write pods
  extraVolumes: []
  # -- Resource requests and limits for the write
  resources: {}
  # -- Grace period to allow the write to shutdown before it is killed. Especially for the ingestor,
  # this must be increased. It must be long enough so writes can be gracefully shutdown flushing/transferring
  # all data and to successfully leave the member ring on shutdown.
  terminationGracePeriodSeconds: 300
  # -- Affinity for write pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "loki.writeSelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
  # -- Node selector for write pods
  nodeSelector: {}
  # -- Tolerations for write pods
  tolerations: []
  persistence:
    # -- Size of persistent disk
    size: 10Gi
    # -- Storage class to be used.
    # If defined, storageClassName: <storageClass>.
    # If set to "-", storageClassName: "", which disables dynamic provisioning.
    # If empty or set to null, no storageClassName spec is
    # set, choosing the default provisioner (gp2 on AWS, standard on GKE, AWS, and OpenStack).
    storageClass: null

# Configuration for the read node(s)
read:
  # -- Number of replicas for the read
  replicas: 3
  autoscaling:
    # -- Enable autoscaling for the read, this is only used if `queryIndex.enabled: true`
    enabled: false
    # -- Minimum autoscaling replicas for the read
    minReplicas: 1
    # -- Maximum autoscaling replicas for the read
    maxReplicas: 3
    # -- Target CPU utilisation percentage for the read
    targetCPUUtilizationPercentage: 60
    # -- Target memory utilisation percentage for the read
    targetMemoryUtilizationPercentage:
  image:
    # -- The Docker registry for the read image. Overrides `loki.image.registry`
    registry: null
    # -- Docker image repository for the read image. Overrides `loki.image.repository`
    repository: null
    # -- Docker image tag for the read image. Overrides `loki.image.tag`
    tag: null
  # -- The name of the PriorityClass for read pods
  priorityClassName: null
  # -- Annotations for read pods
  podAnnotations: {}
  # -- Additional selecto labels for each `read` pod
  selectorLabels: {}
  # -- Labels for read service
  serviceLabels: {}
  # -- Additional CLI args for the read
  extraArgs: []
  # -- Environment variables to add to the read pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the read pods
  extraEnvFrom: []
  # -- Volume mounts to add to the read pods
  extraVolumeMounts: []
  # -- Volumes to add to the read pods
  extraVolumes: []
  # -- Resource requests and limits for the read
  resources: {}
  # -- Grace period to allow the read to shutdown before it is killed
  terminationGracePeriodSeconds: 30
  # -- Affinity for read pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "loki.readSelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
  # -- Node selector for read pods
  nodeSelector: {}
  # -- Tolerations for read pods
  tolerations: []
  persistence:
    # -- Size of persistent disk
    size: 10Gi
    # -- Storage class to be used.
    # If defined, storageClassName: <storageClass>.
    # If set to "-", storageClassName: "", which disables dynamic provisioning.
    # If empty or set to null, no storageClassName spec is
    # set, choosing the default provisioner (gp2 on AWS, standard on GKE, AWS, and OpenStack).
    storageClass: null

# Configuration for the gateway
gateway:
  # -- Specifies whether the gateway should be enabled
  enabled: true
  # -- Number of replicas for the gateway
  replicas: 1
  # -- Enable logging of 2xx and 3xx HTTP requests
  verboseLogging: true
  autoscaling:
    # -- Enable autoscaling for the gateway
    enabled: false
    # -- Minimum autoscaling replicas for the gateway
    minReplicas: 1
    # -- Maximum autoscaling replicas for the gateway
    maxReplicas: 3
    # -- Target CPU utilisation percentage for the gateway
    targetCPUUtilizationPercentage: 60
    # -- Target memory utilisation percentage for the gateway
    targetMemoryUtilizationPercentage:
  # -- See `kubectl explain deployment.spec.strategy` for more
  # -- ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy
  deploymentStrategy:
    type: RollingUpdate
  image:
    # -- The Docker registry for the gateway image
    registry: docker.io
    # -- The gateway image repository
    repository: nginxinc/nginx-unprivileged
    # -- The gateway image tag
    tag: 1.19-alpine
    # -- The gateway image pull policy
    pullPolicy: IfNotPresent
  # -- The name of the PriorityClass for gateway pods
  priorityClassName: null
  # -- Annotations for gateway pods
  podAnnotations: {}
  # -- Additional CLI args for the gateway
  extraArgs: []
  # -- Environment variables to add to the gateway pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the gateway pods
  extraEnvFrom: []
  # -- Volumes to add to the gateway pods
  extraVolumes: []
  # -- Volume mounts to add to the gateway pods
  extraVolumeMounts: []
  # -- The SecurityContext for gateway containers
  podSecurityContext:
    fsGroup: 101
    runAsGroup: 101
    runAsNonRoot: true
    runAsUser: 101
  # -- The SecurityContext for gateway containers
  containerSecurityContext:
    readOnlyRootFilesystem: true
    capabilities:
      drop:
        - ALL
    allowPrivilegeEscalation: false
  # -- Resource requests and limits for the gateway
  resources: {}
  # -- Grace period to allow the gateway to shutdown before it is killed
  terminationGracePeriodSeconds: 30
  # -- Affinity for gateway pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "loki.gatewaySelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
  # -- Node selector for gateway pods
  nodeSelector: {}
  # -- Tolerations for gateway pods
  tolerations: []
  # Gateway service configuration
  service:
    # -- Port of the gateway service
    port: 80
    # -- Type of the gateway service
    type: ClusterIP
    # -- ClusterIP of the gateway service
    clusterIP: null
    # -- (int) Node port if service type is NodePort
    nodePort: null
    # -- Load balancer IPO address if service type is LoadBalancer
    loadBalancerIP: null
    # -- Annotations for the gateway service
    annotations: {}
    # -- Labels for gateway service
    labels: {}
  # Gateway ingress configuration
  ingress:
    # -- Specifies whether an ingress for the gateway should be created
    enabled: false
    # -- Ingress Class Name. MAY be required for Kubernetes versions >= 1.18
    # ingressClassName: nginx
    # -- Annotations for the gateway ingress
    annotations: {}
    # -- Hosts configuration for the gateway ingress
    hosts:
      - host: gateway.loki.example.com
        paths:
          - path: /
            # -- pathType (e.g. ImplementationSpecific, Prefix, .. etc.) might also be required by some Ingress Controllers
            # pathType: Prefix
    # -- TLS configuration for the gateway ingress
    tls:
      - secretName: loki-gateway-tls
        hosts:
          - gateway.loki.example.com
  # Basic auth configuration
  basicAuth:
    # -- Enables basic authentication for the gateway
    enabled: false
    # -- The basic auth username for the gateway
    username: null
    # -- The basic auth password for the gateway
    password: null
    # -- Uses the specified username and password to compute a htpasswd using Sprig's `htpasswd` function.
    # The value is templated using `tpl`. Override this to use a custom htpasswd, e.g. in case the default causes
    # high CPU load.
    htpasswd: >-
      {{ htpasswd (required "'gateway.basicAuth.username' is required" .Values.gateway.basicAuth.username) (required "'gateway.basicAuth.password' is required" .Values.gateway.basicAuth.password) }}

    # -- Existing basic auth secret to use. Must contain '.htpasswd'
    existingSecret: null
  # Configures the readiness probe for the gateway
  readinessProbe:
    httpGet:
      path: /
      port: http
    initialDelaySeconds: 15
    timeoutSeconds: 1
  nginxConfig:
    # -- NGINX log format
    logFormat: |-
      main '$remote_addr - $remote_user [$time_local]  $status '
              '"$request" $body_bytes_sent "$http_referer" '
              '"$http_user_agent" "$http_x_forwarded_for"';
    # -- Allows appending custom configuration to the server block
    serverSnippet: ""
    # -- Allows appending custom configuration to the http block
    httpSnippet: ""
    # -- Config file contents for Nginx. Passed through the `tpl` function to allow templating
    # @default -- See values.yaml
    file: |
      worker_processes  5;  ## Default: 1
      error_log  /dev/stderr;
      pid        /tmp/nginx.pid;
      worker_rlimit_nofile 8192;

      events {
        worker_connections  4096;  ## Default: 1024
      }

      http {
        client_body_temp_path /tmp/client_temp;
        proxy_temp_path       /tmp/proxy_temp_path;
        fastcgi_temp_path     /tmp/fastcgi_temp;
        uwsgi_temp_path       /tmp/uwsgi_temp;
        scgi_temp_path        /tmp/scgi_temp;

        proxy_http_version    1.1;

        default_type application/octet-stream;
        log_format   {{ .Values.gateway.nginxConfig.logFormat }}

        {{- if .Values.gateway.verboseLogging }}
        access_log   /dev/stderr  main;
        {{- else }}

        map $status $loggable {
          ~^[23]  0;
          default 1;
        }
        access_log   /dev/stderr  main  if=$loggable;
        {{- end }}

        sendfile     on;
        tcp_nopush   on;
        resolver {{ .Values.global.dnsService }}.{{ .Values.global.dnsNamespace }}.svc.{{ .Values.global.clusterDomain }};

        {{- with .Values.gateway.nginxConfig.httpSnippet }}
        {{ . | nindent 2 }}
        {{- end }}

        server {
          listen             8080;

          {{- if .Values.gateway.basicAuth.enabled }}
          auth_basic           "Loki";
          auth_basic_user_file /etc/nginx/secrets/.htpasswd;
          {{- end }}

          location = / {
            return 200 'OK';
            auth_basic off;
          }

          location = /api/prom/push {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /api/prom/tail {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          }

          location ~ /api/prom/.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /loki/api/v1/push {
            proxy_pass       http://{{ include "loki.writeFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /loki/api/v1/tail {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          }

          location ~ /loki/api/.* {
            proxy_pass       http://{{ include "loki.readFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          {{- with .Values.gateway.nginxConfig.serverSnippet }}
          {{ . | nindent 4 }}
          {{- end }}
        }
      }

networkPolicy:
  # -- Specifies whether Network Policies should be created
  enabled: false
  metrics:
    # -- Specifies the Pods which are allowed to access the metrics port.
    # As this is cross-namespace communication, you also need the namespaceSelector.
    podSelector: {}
    # -- Specifies the namespaces which are allowed to access the metrics port
    namespaceSelector: {}
    # -- Specifies specific network CIDRs which are allowed to access the metrics port.
    # In case you use namespaceSelector, you also have to specify your kubelet networks here.
    # The metrics ports are also used for probes.
    cidrs: []
  ingress:
    # -- Specifies the Pods which are allowed to access the http port.
    # As this is cross-namespace communication, you also need the namespaceSelector.
    podSelector: {}
    # -- Specifies the namespaces which are allowed to access the http port
    namespaceSelector: {}
  alertmanager:
    # -- Specify the alertmanager port used for alerting
    port: 9093
    # -- Specifies the alertmanager Pods.
    # As this is cross-namespace communication, you also need the namespaceSelector.
    podSelector: {}
    # -- Specifies the namespace the alertmanager is running in
    namespaceSelector: {}
  externalStorage:
    # -- Specify the port used for external storage, e.g. AWS S3
    ports: []
    # -- Specifies specific network CIDRs you want to limit access to
    cidrs: []
  discovery:
    # -- (int) Specify the port used for discovery
    port: null
    # -- Specifies the Pods labels used for discovery.
    # As this is cross-namespace communication, you also need the namespaceSelector.
    podSelector: {}
    # -- Specifies the namespace the discovery Pods are running in
    namespaceSelector: {}

# -------------------------------------
# Configuration for `minio` child chart
# -------------------------------------
minio:
  enabled: true
  # accessKey: enterprise-logs
  # secretKey: supersecret
  buckets:
    - name: chunks
      policy: none
      purge: false
    - name: ruler
      policy: none
      purge: false
    - name: admin
      policy: none
      purge: false
  persistence:
    size: 5Gi
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
