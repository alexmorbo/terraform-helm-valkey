locals {
  # Node scheduling configuration
  # When dedicated_nodes is true, pods will be scheduled only on nodes with:
  # - Label: var.node_group_label = var.dedicated_node_group
  # - Taint: var.dedicated_label = var.dedicated_node_group:NoExecute
  tolerations = var.dedicated_nodes ? [
    {
      key    = var.dedicated_label
      value  = var.dedicated_node_group
      effect = "NoExecute"
    }
  ] : []

  node_selector = var.dedicated_nodes ? {
    (var.node_group_label) = var.dedicated_node_group
  } : {}
}
