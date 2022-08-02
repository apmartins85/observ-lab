global:
  image:
    # -- Overrides the Docker registry globally for all images
    registry: docker.io
  # -- Overrides the priorityClassName for all pods
  priorityClassName: null
  # -- configures cluster domain ("cluster.local" by default)
  clusterDomain: "cluster.local"
  # -- configures DNS service name
  dnsService: "kube-dns"
  # -- configures DNS service namespace
  dnsNamespace: "kube-system"
# -- Overrides the chart's computed fullname
# fullnameOverride: tempo
tempo:
  image:
    # -- The Docker registry
    registry: docker.io
    # -- Docker image repository
    repository: grafana/tempo
    # -- Overrides the image tag whose default is the chart's appVersion
    tag: null
    pullPolicy: IfNotPresent
  readinessProbe:
    httpGet:
      path: /ready
      port: http
    initialDelaySeconds: 30
    timeoutSeconds: 1
  # -- Global labels for all tempo pods
  podLabels: {}
  # -- Common annotations for all pods
  podAnnotations: {}
  # -- SecurityContext holds pod-level security attributes and common container settings
  securityContext: {}
  #  capabilities:
  #    drop:
  #    - ALL
  #  readOnlyRootFilesystem: true
  #  runAsNonRoot: true
  #  runAsUser: 1000
  # -- Structured tempo configuration
  structuredConfig: {}

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

rbac:
  # -- Specifies whether RBAC manifests should be created
  create: false
  # -- Specifies whether a PodSecurityPolicy should be created
  pspEnabled: false

# Configuration for the ingester
ingester:
  # -- Annotations for the ingester StatefulSet
  annotations: {}
  # -- Number of replicas for the ingester
  replicas: 3
  autoscaling:
    # -- Enable autoscaling for the ingester
    enabled: false
    # -- Minimum autoscaling replicas for the ingester
    minReplicas: 1
    # -- Maximum autoscaling replicas for the ingester
    maxReplicas: 3
    # -- Target CPU utilisation percentage for the ingester
    targetCPUUtilizationPercentage: 60
    # -- Target memory utilisation percentage for the ingester
    targetMemoryUtilizationPercentage:
  image:
    # -- The Docker registry for the ingester image. Overrides `tempo.image.registry`
    registry: null
    # -- Docker image repository for the ingester image. Overrides `tempo.image.repository`
    repository: null
    # -- Docker image tag for the ingester image. Overrides `tempo.image.tag`
    tag: null
  # -- The name of the PriorityClass for ingester pods
  priorityClassName: null
  # -- Labels for ingester pods
  podLabels: {}
  # -- Annotations for ingester pods
  podAnnotations: {}
  # -- Additional CLI args for the ingester
  extraArgs: []
  # -- Environment variables to add to the ingester pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the ingester pods
  extraEnvFrom: []
  # -- Resource requests and limits for the ingester
  resources: {}
  # -- Grace period to allow the ingester to shutdown before it is killed. Especially for the ingestor,
  # this must be increased. It must be long enough so ingesters can be gracefully shutdown flushing/transferring
  # all data and to successfully leave the member ring on shutdown.
  terminationGracePeriodSeconds: 300
  # -- Affinity for ingester pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Soft node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.ingesterSelectorLabels" . | nindent 12 }}
            topologyKey: kubernetes.io/hostname
        - weight: 75
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.ingesterSelectorLabels" . | nindent 12 }}
            topologyKey: failure-domain.beta.kubernetes.io/zone
  # -- Node selector for ingester pods
  nodeSelector: {}
  # -- Tolerations for ingester pods
  tolerations: []
  # -- Extra volumes for ingester pods
  extraVolumeMounts: []
  # -- Extra volumes for ingester deployment
  extraVolumes: []
  persistence:
    # -- Enable creating PVCs which is required when using boltdb-shipper
    enabled: false
    # -- Size of persistent disk
    size: 10Gi
    # -- Storage class to be used.
    # If defined, storageClassName: <storageClass>.
    # If set to "-", storageClassName: "", which disables dynamic provisioning.
    # If empty or set to null, no storageClassName spec is
    # set, choosing the default provisioner (gp2 on AWS, standard on GKE, AWS, and OpenStack).
    storageClass: null
  config:
    # -- Number of copies of spans to store in the ingester ring
    replication_factor: 3
    # -- Amount of time a trace must be idle before flushing it to the wal.
    trace_idle_period: null
    # -- How often to sweep all tenants and move traces from live -> wal -> completed blocks.
    flush_check_period: null
    # -- Maximum size of a block before cutting it
    max_block_bytes: null
    # -- Maximum length of time before cutting a block
    max_block_duration: null
    # -- Duration to keep blocks in the ingester after they have been flushed
    complete_block_timeout: null
  service:
    # -- Annotations for ingester service
    annotations: {}

# Configuration for the metrics-generator
metricsGenerator:
  # -- Specifies whether a metrics-generator should be deployed
  enabled: false
  # -- Annotations for the metrics-generator StatefulSet
  annotations: {}
  # -- Number of replicas for the metrics-generator
  replicas: 1
  image:
    # -- The Docker registry for the metrics-generator image. Overrides `tempo.image.registry`
    registry: null
    # -- Docker image repository for the metrics-generator image. Overrides `tempo.image.repository`
    repository: null
    # -- Docker image tag for the metrics-generator image. Overrides `tempo.image.tag`
    tag: null
  # -- The name of the PriorityClass for metrics-generator pods
  priorityClassName: null
  # -- Labels for metrics-generator pods
  podLabels: {}
  # -- Annotations for metrics-generator pods
  podAnnotations: {}
  # -- Additional CLI args for the metrics-generator
  extraArgs: []
  # -- Environment variables to add to the metrics-generator pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the metrics-generator pods
  extraEnvFrom: []
  # -- Resource requests and limits for the metrics-generator
  resources: {}
  # -- Grace period to allow the metrics-generator to shutdown before it is killed. Especially for the ingestor,
  # this must be increased. It must be long enough so metrics-generators can be gracefully shutdown flushing/transferring
  # all data and to successfully leave the member ring on shutdown.
  terminationGracePeriodSeconds: 300
  # -- Affinity for metrics-generator pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "tempo.metricsGeneratorSelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.metricsGeneratorSelectorLabels" . | nindent 12 }}
            topologyKey: failure-domain.beta.kubernetes.io/zone
  # -- Node selector for metrics-generator pods
  nodeSelector: {}
  # -- Tolerations for metrics-generator pods
  tolerations: []
  # -- Extra volumes for metrics-generator pods
  extraVolumeMounts: []
  # -- Extra volumes for metrics-generator deployment
  extraVolumes: []
  # -- Default ports
  ports:
    - name: grpc
      port: 9095
      service: true
    - name: http-memberlist
      port: 7946
      service: false
    - name: http
      port: 3100
      service: true
  config:
    #  MaxItems is the amount of edges that will be stored in the store.
    service_graphs_max_items: 10000
    storage_remote_write: []
    # - url: http://cortex/api/v1/push
    #   send_exemplars: true
    #   headers:
    #     x-scope-orgid: operations
  service:
    # -- Annotations for Metrics Generator service
    annotations: {}

# Configuration for the distributor
distributor:
  # -- Number of replicas for the distributor
  replicas: 1
  autoscaling:
    # -- Enable autoscaling for the distributor
    enabled: false
    # -- Minimum autoscaling replicas for the distributor
    minReplicas: 1
    # -- Maximum autoscaling replicas for the distributor
    maxReplicas: 3
    # -- Target CPU utilisation percentage for the distributor
    targetCPUUtilizationPercentage: 60
    # -- Target memory utilisation percentage for the distributor
    targetMemoryUtilizationPercentage:
  image:
    # -- The Docker registry for the ingester image. Overrides `tempo.image.registry`
    registry: null
    # -- Docker image repository for the ingester image. Overrides `tempo.image.repository`
    repository: null
    # -- Docker image tag for the ingester image. Overrides `tempo.image.tag`
    tag: null
  service:
    # -- Annotations for distributor service
    annotations: {}
    # -- Type of service for the distributor
    type: ClusterIP
    # -- If type is LoadBalancer you can assign the IP to the LoadBalancer
    loadBalancerIP: ""
    # -- If type is LoadBalancer limit incoming traffic from IPs.
    loadBalancerSourceRanges: []
  # -- The name of the PriorityClass for distributor pods
  priorityClassName: null
  # -- Labels for distributor pods
  podLabels: {}
  # -- Annotations for distributor pods
  podAnnotations: {}
  # -- Additional CLI args for the distributor
  extraArgs: []
  # -- Environment variables to add to the distributor pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the distributor pods
  extraEnvFrom: []
  # -- Resource requests and limits for the distributor
  resources: {}
  # -- Grace period to allow the distributor to shutdown before it is killed
  terminationGracePeriodSeconds: 30
  # -- Affinity for distributor pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "tempo.distributorSelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.distributorSelectorLabels" . | nindent 12 }}
            topologyKey: failure-domain.beta.kubernetes.io/zone
  # -- Node selector for distributor pods
  nodeSelector: {}
  # -- Tolerations for distributor pods
  tolerations: []
  # -- Extra volumes for distributor pods
  extraVolumeMounts: []
  # -- Extra volumes for distributor deployment
  extraVolumes: []
  config:
    # -- Enable to log every received trace id to help debug ingestion
    log_received_traces: null
    # -- Disables write extension with inactive ingesters
    extend_writes: null
    # -- List of tags that will not be extracted from trace data for search lookups
    search_tags_deny_list: []

compactor:
  # -- Number of replicas for the compactor
  replicas: 1
  image:
    # -- The Docker registry for the compactor image. Overrides `tempo.image.registry`
    registry: null
    # -- Docker image repository for the compactor image. Overrides `tempo.image.repository`
    repository: null
    # -- Docker image tag for the compactor image. Overrides `tempo.image.tag`
    tag: null
  # -- The name of the PriorityClass for compactor pods
  priorityClassName: null
  # -- Labels for compactor pods
  podLabels: {}
  # -- Annotations for compactor pods
  podAnnotations: {}
  # -- Additional CLI args for the compactor
  extraArgs: []
  # -- Environment variables to add to the compactor pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the compactor pods
  extraEnvFrom: []
  # -- Resource requests and limits for the compactor
  resources: {}
  # -- Grace period to allow the compactor to shutdown before it is killed
  terminationGracePeriodSeconds: 30
  # -- Node selector for compactor pods
  nodeSelector: {}
  # -- Tolerations for compactor pods
  tolerations: []
  # -- Extra volumes for compactor pods
  extraVolumeMounts: []
  # -- Extra volumes for compactor deployment
  extraVolumes: []
  config:
    compaction:
      # -- Duration to keep blocks
      block_retention: 48h
  service:
    # -- Annotations for compactor service
    annotations: {}

# Configuration for the querier
querier:
  # -- Number of replicas for the querier
  replicas: 1
  image:
    # -- The Docker registry for the querier image. Overrides `tempo.image.registry`
    registry: null
    # -- Docker image repository for the querier image. Overrides `tempo.image.repository`
    repository: null
    # -- Docker image tag for the querier image. Overrides `tempo.image.tag`
    tag: null
  # -- The name of the PriorityClass for querier pods
  priorityClassName: null
  # -- Labels for querier pods
  podLabels: {}
  # -- Annotations for querier pods
  podAnnotations: {}
  # -- Additional CLI args for the querier
  extraArgs: []
  # -- Environment variables to add to the querier pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the querier pods
  extraEnvFrom: []
  # -- Resource requests and limits for the querier
  resources: {}
  # -- Grace period to allow the querier to shutdown before it is killed
  terminationGracePeriodSeconds: 30
  # -- Affinity for querier pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "tempo.querierSelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.querierSelectorLabels" . | nindent 12 }}
            topologyKey: failure-domain.beta.kubernetes.io/zone
  # -- Node selector for querier pods
  nodeSelector: {}
  # -- Tolerations for querier pods
  tolerations: []
  # -- Extra volumes for querier pods
  extraVolumeMounts: []
  # -- Extra volumes for querier deployment
  extraVolumes: []
  config:
    frontend_worker:
      # -- grpc client configuration
      grpc_client_config: {}
  service:
    # -- Annotations for querier service
    annotations: {}

# Configuration for the query-frontend
queryFrontend:
  query:
    # -- Required for grafana version <7.5 for compatibility with jaeger-ui. Doesn't work on ARM arch
    enabled: true
    image:
      # -- The Docker registry for the query-frontend image. Overrides `tempo.image.registry`
      registry: null
      # -- Docker image repository for the query-frontend image. Overrides `tempo.image.repository`
      repository: grafana/tempo-query
      # -- Docker image tag for the query-frontend image. Overrides `tempo.image.tag`
      tag: null
    # -- Resource requests and limits for the query
    resources: {}
    # -- Additional CLI args for tempo-query pods
    extraArgs: []
    # -- Environment variables to add to the tempo-query pods
    extraEnv: []
    # -- Environment variables from secrets or configmaps to add to the tempo-query pods
    extraEnvFrom: []
    # -- Extra volumes for tempo-query pods
    extraVolumeMounts: []
    # -- Extra volumes for tempo-query deployment
    extraVolumes: []
    config: |
      backend: 127.0.0.1:3100
  # -- Number of replicas for the query-frontend
  replicas: 1
  autoscaling:
    # -- Enable autoscaling for the query-frontend
    enabled: false
    # -- Minimum autoscaling replicas for the query-frontend
    minReplicas: 1
    # -- Maximum autoscaling replicas for the query-frontend
    maxReplicas: 3
    # -- Target CPU utilisation percentage for the query-frontend
    targetCPUUtilizationPercentage: 60
    # -- Target memory utilisation percentage for the query-frontend
    targetMemoryUtilizationPercentage:
  image:
    # -- The Docker registry for the query-frontend image. Overrides `tempo.image.registry`
    registry: null
    # -- Docker image repository for the query-frontend image. Overrides `tempo.image.repository`
    repository: null
    # -- Docker image tag for the query-frontend image. Overrides `tempo.image.tag`
    tag: null
  service:
    # -- Annotations for queryFrontend service
    annotations: {}
    # -- Type of service for the queryFrontend
    type: ClusterIP
  serviceDiscovery:
    # -- Annotations for queryFrontendDiscovery service
    annotations: {}
  # -- The name of the PriorityClass for query-frontend pods
  priorityClassName: null
  # -- Labels for queryFrontend pods
  podLabels: {}
  # -- Annotations for query-frontend pods
  podAnnotations: {}
  # -- Additional CLI args for the query-frontend
  extraArgs: []
  # -- Environment variables to add to the query-frontend pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to the query-frontend pods
  extraEnvFrom: []
  # -- Resource requests and limits for the query-frontend
  resources: {}
  # -- Grace period to allow the query-frontend to shutdown before it is killed
  terminationGracePeriodSeconds: 30
  # -- Affinity for query-frontend pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "tempo.queryFrontendSelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.queryFrontendSelectorLabels" . | nindent 12 }}
            topologyKey: failure-domain.beta.kubernetes.io/zone
  # -- Node selector for query-frontend pods
  nodeSelector: {}
  # -- Tolerations for query-frontend pods
  tolerations: []
  # -- Extra volumes for query-frontend pods
  extraVolumeMounts: []
  # -- Extra volumes for query-frontend deployment
  extraVolumes: []

search:
  # -- Enable Tempo search
  enabled: true

multitenancyEnabled: false

traces:
  jaeger:
    grpc:
      # -- Enable Tempo to ingest Jaeger GRPC traces
      enabled: true
      # -- Jaeger GRPC receiver config
      receiverConfig: {}
    thriftBinary:
      # -- Enable Tempo to ingest Jaeger Thrift Binary traces
      enabled: true
      # -- Jaeger Thrift Binary receiver config
      receiverConfig: {}
    thriftCompact:
      # -- Enable Tempo to ingest Jaeger Thrift Compact traces
      enabled: true
      # -- Jaeger Thrift Compact receiver config
      receiverConfig: {}
    thriftHttp:
      # -- Enable Tempo to ingest Jaeger Thrift HTTP traces
      enabled: true
      # -- Jaeger Thrift HTTP receiver config
      receiverConfig: {}
  zipkin:
    # -- Enable Tempo to ingest Zipkin traces
    enabled: false
    # -- Zipkin receiver config
    receiverConfig: {}
  otlp:
    http:
      # -- Enable Tempo to ingest Open Telemetry HTTP traces
      enabled: true
      # -- HTTP receiver advanced config
      receiverConfig: {}
    grpc:
      # -- Enable Tempo to ingest Open Telemetry GRPC traces
      enabled: true
      # -- GRPC receiver advanced config
      receiverConfig: {}
  opencensus:
    # -- Enable Tempo to ingest Open Census traces
    enabled: false
    # -- Open Census receiver config
    receiverConfig: {}
  # -- Enable Tempo to ingest traces from Kafka. Reference: https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/kafkareceiver
  kafka: {}

config: |
  multitenancy_enabled: {{ .Values.multitenancyEnabled }}
  search_enabled: {{ .Values.search.enabled }}
  metrics_generator_enabled: {{ .Values.metricsGenerator.enabled }}
  compactor:
    compaction:
      block_retention: {{ .Values.compactor.config.compaction.block_retention }}
    ring:
      kvstore:
        store: memberlist
  {{- if .Values.metricsGenerator.enabled }}
  metrics_generator:
    ring:
      kvstore:
        store: memberlist
    processor:
      service_graphs:
        max_items: {{ .Values.metricsGenerator.config.service_graphs_max_items }}
    storage:
      path: /var/tempo/wal
      remote_write:
        {{- toYaml .Values.metricsGenerator.config.storage_remote_write | nindent 6}}
  {{- end }}
  distributor:
    ring:
      kvstore:
        store: memberlist
    receivers:
      {{- if  or (.Values.traces.jaeger.thriftCompact.enabled) (.Values.traces.jaeger.thriftBinary.enabled) (.Values.traces.jaeger.thriftHttp.enabled) (.Values.traces.jaeger.grpc.enabled) }}
      jaeger:
        protocols:
          {{- if .Values.traces.jaeger.thriftCompact.enabled }}
          thrift_compact:
            {{- $mergedJaegerThriftCompactConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:6831") .Values.traces.jaeger.thriftCompact.receiverConfig }}
            {{- toYaml $mergedJaegerThriftCompactConfig | nindent 10 }}
          {{- end }}
          {{- if .Values.traces.jaeger.thriftBinary.enabled }}
          thrift_binary:
            {{- $mergedJaegerThriftBinaryConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:6832") .Values.traces.jaeger.thriftBinary.receiverConfig }}
            {{- toYaml $mergedJaegerThriftBinaryConfig | nindent 10 }}
          {{- end }}
          {{- if .Values.traces.jaeger.thriftHttp.enabled }}
          thrift_http:
            {{- $mergedJaegerThriftHttpConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:14268") .Values.traces.jaeger.thriftHttp.receiverConfig }}
            {{- toYaml $mergedJaegerThriftHttpConfig | nindent 10 }}
          {{- end }}
          {{- if .Values.traces.jaeger.grpc.enabled }}
          grpc:
            {{- $mergedJaegerGrpcConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:14250") .Values.traces.jaeger.grpc.receiverConfig }}
            {{- toYaml $mergedJaegerGrpcConfig | nindent 10 }}
          {{- end }}
      {{- end }}
      {{- if .Values.traces.zipkin.enabled }}
      zipkin:
        {{- $mergedZipkinReceiverConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:9411") .Values.traces.zipkin.receiverConfig }}
        {{- toYaml $mergedZipkinReceiverConfig | nindent 6 }}
      {{- end }}
      {{- if or (.Values.traces.otlp.http.enabled) (.Values.traces.otlp.grpc.enabled) }}
      otlp:
        protocols:
          {{- if .Values.traces.otlp.http.enabled }}
          http:
            {{- $mergedOtlpHttpReceiverConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:4318") .Values.traces.otlp.http.receiverConfig }}
            {{- toYaml $mergedOtlpHttpReceiverConfig | nindent 10 }}
          {{- end }}
          {{- if .Values.traces.otlp.grpc.enabled }}
          grpc:
            {{- $mergedOtlpGrpcReceiverConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:4317") .Values.traces.otlp.grpc.receiverConfig }}
            {{- toYaml $mergedOtlpGrpcReceiverConfig | nindent 10 }}
          {{- end }}
      {{- end }}
      {{- if .Values.traces.opencensus.enabled }}
      opencensus:
        {{- $mergedOpencensusReceiverConfig := mustMergeOverwrite (dict "endpoint" "0.0.0.0:55678") .Values.traces.opencensus.receiverConfig }}
        {{- toYaml $mergedOpencensusReceiverConfig | nindent 6 }}
      {{- end }}
      {{- if .Values.traces.kafka }}
      kafka:
        {{- toYaml .Values.traces.kafka | nindent 6 }}
      {{- end }}
    {{- if .Values.distributor.config.log_received_traces }}
    log_received_traces: {{ .Values.distributor.config.log_received_traces }}
    {{- end }}
    {{- if .Values.distributor.config.extend_writes }}
    extend_writes: {{ .Values.distributor.config.extend_writes }}
    {{- end }}
    {{- if .Values.distributor.config.search_tags_deny_list }}
    search_tags_deny_list:
      {{- with .Values.distributor.config.search_tags_deny_list }}
      {{- toYaml . | nindent 4 }}
      {{- end }}
    {{- end }}
  querier:
    frontend_worker:
      frontend_address: {{ include "tempo.queryFrontendFullname" . }}-discovery:9095
      {{- if .Values.querier.config.frontend_worker.grpc_client_config }}
      grpc_client_config:
        {{- toYaml .Values.querier.config.frontend_worker.grpc_client_config | nindent 6 }}
      {{- end }}
  ingester:
    lifecycler:
      ring:
        replication_factor: {{ .Values.ingester.config.replication_factor }}
        kvstore:
          store: memberlist
      tokens_file_path: /var/tempo/tokens.json
    {{- if .Values.ingester.config.trace_idle_period }}
    trace_idle_period: {{ .Values.ingester.config.trace_idle_period }}
    {{- end }}
    {{- if .Values.ingester.config.flush_check_period }}
    flush_check_period: {{ .Values.ingester.config.flush_check_period }}
    {{- end }}
    {{- if .Values.ingester.config.max_block_bytes }}
    max_block_bytes: {{ .Values.ingester.config.max_block_bytes }}
    {{- end }}
    {{- if .Values.ingester.config.max_block_duration }}
    max_block_duration: {{ .Values.ingester.config.max_block_duration }}
    {{- end }}
    {{- if .Values.ingester.config.complete_block_timeout }}
    complete_block_timeout: {{ .Values.ingester.config.complete_block_timeout }}
    {{- end }}
  memberlist:
    abort_if_cluster_join_fails: false
    join_members:
      - {{ include "tempo.fullname" . }}-gossip-ring
  overrides:
    {{- toYaml .Values.global_overrides | nindent 2 }}
  server:
    http_listen_port: {{ .Values.server.httpListenPort }}
    log_level: {{ .Values.server.logLevel }}
    log_format: {{ .Values.server.logFormat }}
    grpc_server_max_recv_msg_size: {{ .Values.server.grpc_server_max_recv_msg_size }}
    grpc_server_max_send_msg_size: {{ .Values.server.grpc_server_max_send_msg_size }}
  storage:
    trace:
      backend: {{.Values.storage.trace.backend}}
      {{- if eq .Values.storage.trace.backend "gcs"}}
      gcs:
        {{- toYaml .Values.storage.trace.gcs | nindent 6}}
      {{- end}}
      {{- if eq .Values.storage.trace.backend "s3"}}
      s3:
        {{- toYaml .Values.storage.trace.s3 | nindent 6}}
      {{- end}}
      {{- if eq .Values.storage.trace.backend "azure"}}
      azure:
        {{- toYaml .Values.storage.trace.azure | nindent 6}}
      {{- end}}
      blocklist_poll: 5m
      local:
        path: /var/tempo/traces
      wal:
        path: /var/tempo/wal
      cache: memcached
      memcached:
        consistent_hash: true
        host: {{ include "tempo.fullname" . }}-memcached
        service: memcached-client
        timeout: 500ms

# Set Tempo server configuration
# Refers to https://grafana.com/docs/tempo/latest/configuration/#server
server:
  # --  HTTP server listen host
  httpListenPort: 3100
  # -- Log level. Can be set to trace, debug, info (default), warn error, fatal, panic
  logLevel: info
  # -- Log format. Can be set to logfmt (default) or json.
  logFormat: logfmt
  # -- Max gRPC message size that can be received
  grpc_server_max_recv_msg_size: 4194304
  # -- Max gRPC message size that can be sent
  grpc_server_max_send_msg_size: 4194304
# To configure a different storage backend instead of local storage:
# storage:
#   trace:
#     backend: azure
#     azure:
#       container-name:
#       storage-account-name:
#       storage-account-key:
storage:
  trace:
    # -- The supported storage backends are gcs, s3 and azure, as specified in https://grafana.com/docs/tempo/latest/configuration/#storage
    backend: local
    local:
      path: /var/tempo/traces
    wal:
      path: /var/tempo/wal

# Global overrides
global_overrides:
  per_tenant_override_config: /conf/overrides.yaml
  # metrics_generator_processors:
  #   - service-graphs
  #   - span-metrics

# Per tenants overrides
overrides: |
  overrides: {}

# memcached is for all of the Tempo pieces to coordinate with each other.
# you can use your self memcacherd by set enable: false and host + service
memcached:
  # -- Specified whether the memcached cachce should be enabled
  enabled: true
  image:
    # -- The Docker registry for the Memcached image. Overrides `global.image.registry`
    registry: null
    # -- Memcached Docker image repository
    repository: memcached
    # -- Memcached Docker image tag
    tag: 1.5.17-alpine
    # -- Memcached Docker image pull policy
    pullPolicy: IfNotPresent
  host: memcached
  # Number of replicas for memchached
  replicas: 1
  # -- Additional CLI args for memcached
  extraArgs: []
  # -- Environment variables to add to memcached pods
  extraEnv: []
  # -- Environment variables from secrets or configmaps to add to memcached pods
  extraEnvFrom: []
  # -- Labels for memcached pods
  podLabels: {}
  # -- Annotations for memcached pods
  podAnnotations: {}
  # -- Resource requests and limits for memcached
  resources: {}
  # -- Affinity for memcached pods. Passed through `tpl` and, thus, to be configured as string
  # @default -- Hard node and soft zone anti-affinity
  affinity: |
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              {{- include "tempo.memcachedSelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.memcachedSelectorLabels" . | nindent 12 }}
            topologyKey: failure-domain.beta.kubernetes.io/zone
  service:
    # -- Annotations for memcached service
    annotations: {}

memcachedExporter:
  # -- Specifies whether the Memcached Exporter should be enabled
  enabled: false
  image:
    # -- The Docker registry for the Memcached Exporter image. Overrides `global.image.registry`
    registry: null
    # -- Memcached Exporter Docker image repository
    repository: prom/memcached-exporter
    # -- Memcached Exporter Docker image tag
    tag: v0.8.0
    # -- Memcached Exporter Docker image pull policy
    pullPolicy: IfNotPresent
    # -- Memcached Exporter resource requests and limits
  resources: {}

# ServiceMonitor configuration
serviceMonitor:
  # -- If enabled, ServiceMonitor resources for Prometheus Operator are created
  enabled: false
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
  # -- ServiceMonitor metric relabel configs to apply to samples before ingestion
  # https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#endpoint
  metricRelabelings: []
  # -- ServiceMonitor will use http by default, but you can pick https as well
  scheme: http
  # -- ServiceMonitor will use these tlsConfig settings to make the health check requests
  tlsConfig: null

# Rules for the Prometheus Operator
prometheusRule:
  # -- If enabled, a PrometheusRule resource for Prometheus Operator is created
  enabled: false
  # -- Alternative namespace for the PrometheusRule resource
  namespace: null
  # -- PrometheusRule annotations
  annotations: {}
  # -- Additional PrometheusRule labels
  labels: {}
  # -- Contents of Prometheus rules file
  groups: []
  # - name: loki-rules
  #   rules:
  #     - record: job:loki_request_duration_seconds_bucket:sum_rate
  #       expr: sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job)
  #     - record: job_route:loki_request_duration_seconds_bucket:sum_rate
  #       expr: sum(rate(loki_request_duration_seconds_bucket[1m])) by (le, job, route)
  #     - record: node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate
  #       expr: sum(rate(container_cpu_usage_seconds_total[1m])) by (node, namespace, pod, container)

# Configuration for the gateway
gateway:
  # -- Specifies whether the gateway should be enabled
  enabled: false
  # -- Number of replicas for the gateway
  replicas: 1
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
  # -- Enable logging of 2xx and 3xx HTTP requests
  verboseLogging: true
  image:
    # -- The Docker registry for the gateway image. Overrides `global.image.registry`
    registry: null
    # -- The gateway image repository
    repository: nginxinc/nginx-unprivileged
    # -- The gateway image tag
    tag: 1.19-alpine
    # -- The gateway image pull policy
    pullPolicy: IfNotPresent
  # -- The name of the PriorityClass for gateway pods
  priorityClassName: null
  # -- Labels for gateway pods
  podLabels: {}
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
              {{- include "tempo.gatewaySelectorLabels" . | nindent 10 }}
          topologyKey: kubernetes.io/hostname
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          podAffinityTerm:
            labelSelector:
              matchLabels:
                {{- include "tempo.gatewaySelectorLabels" . | nindent 12 }}
            topologyKey: failure-domain.beta.kubernetes.io/zone
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
    # -- Node port if service type is NodePort
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
      - host: gateway.tempo.example.com
        paths:
          - path: /
            # -- pathType (e.g. ImplementationSpecific, Prefix, .. etc.) might also be required by some Ingress Controllers
            # pathType: Prefix
    # -- TLS configuration for the gateway ingress
    tls:
      - secretName: tempo-gateway-tls
        hosts:
          - gateway.tempo.example.com
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
          auth_basic           "Tempo";
          auth_basic_user_file /etc/nginx/secrets/.htpasswd;
          {{- end }}

          location = / {
            return 200 'OK';
            auth_basic off;
          }

          location = /jaeger/api/traces {
            proxy_pass       http://{{ include "tempo.distributorFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:14268/api/traces;
          }

          location = /zipkin/spans {
            proxy_pass       http://{{ include "tempo.distributorFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:9411/spans;
          }

          location = /otlp/v1/traces {
            proxy_pass       http://{{ include "tempo.distributorFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:4318/v1/traces;
          }

          location ^~ /api {
            proxy_pass       http://{{ include "tempo.queryFrontendFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /flush {
            proxy_pass       http://{{ include "tempo.ingesterFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /shutdown {
            proxy_pass       http://{{ include "tempo.ingesterFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /distributor/ring {
            proxy_pass       http://{{ include "tempo.distributorFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /ingester/ring {
            proxy_pass       http://{{ include "tempo.distributorFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          location = /compactor/ring {
            proxy_pass       http://{{ include "tempo.compactorFullname" . }}.{{ .Release.Namespace }}.svc.{{ .Values.global.clusterDomain }}:3100$request_uri;
          }

          {{- with .Values.gateway.nginxConfig.serverSnippet }}
          {{ . | nindent 4 }}
          {{- end }}
        }
      }
