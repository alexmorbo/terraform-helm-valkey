output "valkey_port" {
  value = var.valkey_port
}

output "sentinel_port" {
  value = var.sentinel_port
}

output "sentinel_host" {
  value = "${var.name}-headless.${local.namespace}"
}

output "hosts" {
  value = [for i in range(var.slave_count) : "${local.host_name}-${i}.${var.name}-headless.${local.namespace}"]
}

output "primary_name" {
  value = local.primary_name
}

output "password" {
  value     = local.valkey_password
  sensitive = true
}
