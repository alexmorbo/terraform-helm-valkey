resource "random_password" "valkey_password" {
  count = var.use_password && var.password == null ? 1 : 0

  length  = 24
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "kubernetes_namespace" "default" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = coalesce(var.namespace_override, var.name)
  }
}

resource "kubernetes_secret" "valkey_password" {
  count = local.use_password ? 1 : 0

  metadata {
    name      = "${var.name}-password"
    namespace = local.namespace
  }

  data = {
    "valkey-password" = local.valkey_password
  }

  type = "Opaque"
}

locals {
  namespace = var.create_namespace ? coalesce(kubernetes_namespace.default[0].metadata[0].name, var.name) : coalesce(var.namespace_override, var.name)

  use_password          = coalesce(var.use_password, var.password != null)
  sentinel_use_password = coalesce(var.sentinel_use_password, local.use_password)
  primary_name          = var.name
  valkey_password       = var.password != null ? var.password : (var.use_password ? random_password.valkey_password[0].result : null)

  values = {
    architecture = var.cluster_enabled ? "replication" : "standalone"

    commonConfiguration = var.common_configuration

    auth = {
      enabled                   = local.use_password
      password                  = ""
      sentinel                  = local.sentinel_use_password
      existingSecret            = local.use_password ? kubernetes_secret.valkey_password[0].metadata[0].name : ""
      existingSecretPasswordKey = "valkey-password"
      usePasswordFiles          = true
      usePasswordFileFromSecret = true
    }

    global = {
      security = {
        allowInsecureImages = true
      }
      storageClass  = var.storage_class
      imageRegistry = var.image_registry
    }

    metrics = {
      image = {
        tag = var.metrics_tag
      }
      enabled        = var.metrics_enabled
      resources      = var.metrics_resources
      podAnnotations = null
      service = {
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9121"
        }
      }
      serviceMonitor = { enabled = var.service_monitor_enabled }
    }

    primary = {
      resources    = var.valkey_resources
      nodeSelector = local.node_selector
      tolerations  = local.tolerations
      pdb = {
        create         = var.pod_disruption_budget_enabled
        minAvailable   = ""
        maxUnavailable = var.pod_disruption_budget_max_unavailable
      }
    }

    replica = {
      resources    = var.valkey_resources
      affinity     = var.valkey_affinity
      nodeSelector = local.node_selector
      tolerations  = local.tolerations
      persistence = {
        size = var.valkey_persistence_size
      }
      pdb = {
        create         = var.pod_disruption_budget_enabled
        minAvailable   = ""
        maxUnavailable = var.pod_disruption_budget_max_unavailable
      }
    }

    sentinel = {
      enabled               = var.sentinel_enabled
      primarySet            = local.primary_name
      quorum                = coalesce(var.sentinel_quorum, var.slave_count, 2)
      downAfterMilliseconds = var.sentinel_down_after_milliseconds
      failoverTimeout       = var.sentinel_failover_timeout
      resources             = var.sentinel_resources
    }

    volumePermissions = {
      enabled = true
    }
  }
}

resource "helm_release" "default" {
  chart       = "valkey"
  version     = var.chart_version
  repository  = "oci://registry-1.docker.io/bitnamicharts"
  max_history = var.helm_history_count
  name        = var.name
  namespace   = local.namespace
  atomic      = var.atomic_release
  timeout     = var.helm_timeout

  values = [yamlencode(local.values)]
}

locals {
  host_name = "${helm_release.default.name}-${(var.cluster_enabled && var.sentinel_enabled) ? "node" : "master"}"
}

resource "kubernetes_manifest" "alerts" {
  count = var.service_monitor_enabled ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "valkey"
      namespace = local.namespace
    }
    spec = {
      groups = [
        {
          name = "valkey"
          rules = [
            {
              alert = "Valkey instance is down"
              expr  = "min(redis_up{namespace=\"${local.namespace}\"}) by (release, namespace) < 1"
              for   = "20m"
              labels = {
                severity = var.alerts_severity
              }
              annotations = {
                runbook = "valkey-instance-is-down"
              }
            },
            {
              alert = "Valkey AOF is larger than ${var.alert_treshold_size}g"
              expr  = "max(redis_aof_current_size_bytes{namespace=\"${local.namespace}\"}) by (app, app_kubernetes_io_instance, namespace, node, release) > ${var.alert_treshold_size} * 1024 * 1024 * 1024"
              for   = "10m"
              labels = {
                severity = var.alerts_severity
              }
              annotations = {
                description = "Valkey AOF is larger than ${var.alert_treshold_size}g"
                runbook     = "valkey-aof-is-critical"
              }
            },
          ]
        }
      ]
    }
  }
}
