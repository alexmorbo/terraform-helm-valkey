variable "name" {
  type = string

  default = "valkey"
}

variable "create_namespace" {
  type = bool

  default = true
}

variable "namespace_override" {
  type = string

  default = null
}

variable "chart_version" {
  type = string

  default = "3.0.30"
}

variable "atomic_release" {
  type = bool

  default = false
}

variable "storage_class" {
  type = string

  default = ""
}

variable "use_password" {
  type = bool

  default = null
}

variable "sentinel_use_password" {
  type = bool

  default = null
}

variable "password" {
  type = string

  default = null
}

variable "cluster_enabled" {
  type = bool

  default = true
}

variable "slave_count" {
  type = number

  default = 3
}

variable "metrics_enabled" {
  type = bool

  default = true
}

variable "metrics_resources" {
  type = map(any)

  default = {}
}

variable "metrics_tag" {
  type = string

  default = "1.70.0-debian-12-r2"
}

variable "service_monitor_enabled" {
  type = bool

  default = false
}

variable "pod_disruption_budget_enabled" {
  type = bool

  default = true
}

variable "pod_disruption_budget_max_unavailable" {
  type = number

  default = 1
}

variable "valkey_port" {
  type = number

  default = 6379
}

variable "valkey_resources" {
  type = map(any)

  default = {}
}

variable "valkey_affinity" {
  type = map(any)

  default = {}
}

variable "dedicated_nodes" {
  description = "Whether to use dedicated nodes for the valkey deployments. When enabled, deployments will use nodeSelector and tolerations to schedule pods on specific nodes."
  type        = bool
  default     = false
}

variable "dedicated_node_group" {
  description = "The node group label to use when dedicated_nodes is true. This should match the label on your dedicated nodes (e.g., 'control-plane', 'worker', 'dedicated')."
  type        = string
  default     = ""
}

variable "node_group_label" {
  description = "The label key for node group selection"
  type        = string
  default     = "company.com/group"
}

variable "dedicated_label" {
  description = "The label key for dedicated node selection"
  type        = string
  default     = "company.com/dedicated"
}

variable "valkey_persistence_size" {
  type = string

  default = "8Gi"
}

variable "sentinel_enabled" {
  type = bool

  default = true
}

variable "sentinel_quorum" {
  type = number

  default = 2
}

variable "sentinel_down_after_milliseconds" {
  type = number

  default = 60000
}

variable "sentinel_failover_timeout" {
  type = number

  default = 180000
}

variable "sentinel_port" {
  type = number

  default = 26379
}

variable "sentinel_resources" {
  type = map(any)

  default = {}
}

variable "alerts_severity" {
  type = string

  default = "warning"
}

variable "alert_treshold_size" {
  type = string

  default = "6"
}

variable "image_registry" {
  type = string

  default = null
}

variable "helm_timeout" {
  type = number

  default = 600
}

variable "common_configuration" {
  type = string

  default = <<-EOT
    # User-supplied common configuration:
    # Enable AOF https://valkey.io/docs/topics/persistence.html
    appendonly yes
    # Disable RDB persistence, AOF persistence already enabled.
    save ""
    # End of common configuration
  EOT
}

variable "helm_history_count" {
  type = number

  default = 10
}
