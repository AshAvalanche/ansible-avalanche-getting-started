output "nodes" {
  description = "LXD container names and their port mappings"
  value = {
    for name, node in local.nodes : name => {
      lxd_hostname  = "${name}.lxd"
      http_port     = node.http_port
      staking_port  = node.staking_port
    }
  }
}

output "lxd_host_address" {
  description = "Address of the LXD host (used as public IP for AvalancheGo)"
  value       = var.lxd_host_address
}
