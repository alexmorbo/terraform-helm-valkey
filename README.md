# Terraform Helm Valkey Module

This Terraform module deploys Valkey (Redis fork) on Kubernetes using Helm charts. It provides a complete solution for deploying Valkey with optional clustering, sentinel support, monitoring, and dedicated node scheduling.

## Features

- **Standalone and Cluster Modes**: Deploy Valkey as standalone or with replication
- **Sentinel Support**: High availability with Redis Sentinel
- **Authentication**: Optional password-based authentication
- **Monitoring**: Built-in Prometheus metrics and ServiceMonitor support
- **Dedicated Nodes**: Schedule pods on specific nodes with custom labels and tolerations
- **Persistent Storage**: Configurable persistent volumes
- **Resource Management**: CPU and memory limits/requests
- **Pod Disruption Budgets**: Configurable PDB for high availability
- **Custom Configuration**: Valkey configuration via common_configuration variable

## Usage

### Basic Example

```hcl
module "valkey" {
  source = "github.com/alexmorbo/terraform-helm-valkey"

  name                = "valkey"
  create_namespace    = true
  cluster_enabled     = true
  slave_count         = 3
  sentinel_enabled    = true
  use_password        = true
  storage_class       = "fast-ssd"
  metrics_enabled     = true
  service_monitor_enabled = true
}
```

### Advanced Example with Dedicated Nodes

```hcl
module "valkey" {
  source = "github.com/alexmorbo/terraform-helm-valkey"

  name                = "valkey"
  create_namespace    = true
  cluster_enabled     = true
  slave_count         = 3
  sentinel_enabled    = true
  use_password        = true
  storage_class       = "fast-ssd"

  # Dedicated node scheduling
  dedicated_nodes     = true
  dedicated_node_group = "infra"
  node_group_label    = "company.com/group"
  dedicated_label     = "company.com/dedicated"

  # Resource configuration
  valkey_resources = {
    limits = {
      cpu    = "1000m"
      memory = "1Gi"
    }
    requests = {
      cpu    = "200m"
      memory = "256Mi"
    }
  }

  sentinel_resources = {
    limits = {
      cpu    = "200m"
      memory = "256Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }

  # Monitoring
  metrics_enabled = true
  service_monitor_enabled = true
  metrics_resources = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the Valkey deployment | `string` | `"valkey"` | no |
| create_namespace | Whether to create a namespace | `bool` | `true` | no |
| namespace_override | Override namespace name | `string` | `null` | no |
| chart_version | Helm chart version | `string` | `"3.0.30"` | no |
| atomic_release | Whether to use atomic release | `bool` | `false` | no |
| storage_class | Storage class for persistent volumes | `string` | `""` | no |
| use_password | Enable password authentication | `bool` | `null` | no |
| password | Valkey password (if not provided, random password will be generated) | `string` | `null` | no |
| sentinel_use_password | Enable password for Sentinel | `bool` | `null` | no |
| cluster_enabled | Enable cluster mode | `bool` | `true` | no |
| slave_count | Number of replica nodes | `number` | `3` | no |
| metrics_enabled | Enable Prometheus metrics | `bool` | `true` | no |
| service_monitor_enabled | Enable ServiceMonitor for Prometheus | `bool` | `false` | no |
| metrics_resources | Resource limits for metrics container | `map(any)` | `{}` | no |
| metrics_tag | Metrics container image tag | `string` | `"1.70.0-debian-12-r2"` | no |
| pod_disruption_budget_enabled | Enable Pod Disruption Budget | `bool` | `true` | no |
| pod_disruption_budget_max_unavailable | Max unavailable pods for PDB | `number` | `1` | no |
| valkey_resources | Resource limits for Valkey containers | `map(any)` | `{}` | no |
| valkey_affinity | Affinity rules for Valkey pods | `map(any)` | `{}` | no |
| valkey_persistence_size | Size of persistent volume | `string` | `"8Gi"` | no |
| sentinel_enabled | Enable Redis Sentinel | `bool` | `true` | no |
| sentinel_quorum | Sentinel quorum count | `number` | `2` | no |
| sentinel_down_after_milliseconds | Sentinel down detection time | `number` | `60000` | no |
| sentinel_failover_timeout | Sentinel failover timeout | `number` | `180000` | no |
| sentinel_resources | Resource limits for Sentinel containers | `map(any)` | `{}` | no |
| dedicated_nodes | Schedule pods on dedicated nodes | `bool` | `false` | no |
| dedicated_node_group | Node group label value for dedicated nodes | `string` | `""` | no |
| node_group_label | Label key for node group selection | `string` | `"company.com/group"` | no |
| dedicated_label | Label key for dedicated node selection | `string` | `"company.com/dedicated"` | no |
| alerts_severity | Severity level for Prometheus alerts | `string` | `"warning"` | no |
| alert_treshold_size | AOF size threshold for alerts (GB) | `string` | `"6"` | no |
| image_registry | Custom image registry | `string` | `null` | no |
| helm_timeout | Helm operation timeout | `number` | `600` | no |
| helm_history_count | Number of Helm history entries to keep | `number` | `10` | no |
| common_configuration | Custom Valkey configuration | `string` | See default | no |

## Outputs

| Name | Description |
|------|-------------|
| valkey_port | Valkey service port |
| sentinel_port | Sentinel service port |
| sentinel_host | Sentinel hostname |
| hosts | List of Valkey hostnames |
| primary_name | Primary Valkey instance name |
| password | Valkey password (sensitive) |

## Dedicated Node Scheduling

When `dedicated_nodes = true`, the module will:

1. **Node Selector**: Schedule pods only on nodes with the specified group label
2. **Tolerations**: Add tolerations for dedicated node taints
3. **Customizable Labels**: Use configurable label keys via `node_group_label` and `dedicated_label`

### Example Node Setup

```bash
# Label nodes for group selection
kubectl label nodes node-1 company.com/group=infra
kubectl label nodes node-2 company.com/group=infra

# Taint nodes for dedicated scheduling
kubectl taint nodes node-1 company.com/dedicated=infra:NoExecute
kubectl taint nodes node-2 company.com/dedicated=infra:NoExecute
```

## Monitoring

The module supports Prometheus monitoring with:

- **Metrics Collection**: Built-in metrics exporter
- **ServiceMonitor**: Automatic Prometheus target discovery
- **Alerts**: Pre-configured PrometheusRule for common issues:
  - Valkey instance down
  - AOF size threshold exceeded

## Security

- **Password Authentication**: Optional password protection
- **Secret Management**: Passwords stored in Kubernetes secrets
- **Network Policies**: Compatible with Kubernetes network policies

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| helm | >= 2.0, < 3.0 |
| kubernetes | >= 2.6, < 3.0 |
| random | >= 3.0, < 4.0 |

## Providers

| Name | Version |
|------|---------|
| helm | >= 2.0, < 3.0 |
| kubernetes | >= 2.6, < 3.0 |
| random | >= 3.0, < 4.0 |

## License

This module is released under the MIT License.
