variable "lxd_host_address" {
  type        = string
  description = "IP or hostname of the remote LXD machine"
}

variable "lxd_ssh_user" {
  type        = string
  description = "SSH user on the LXD host"
  default     = "ubuntu"
}

variable "ssh_public_key_file" {
  type        = string
  description = "Path to the SSH public key to inject into containers"
  default     = "~/.ssh/id_ed25519.pub"
}

variable "nodes_count" {
  type        = number
  description = "Number of LXD containers to create"
  default     = 5
}

variable "node_cpu" {
  type        = number
  description = "vCPUs per container (0 = LXD default, unlimited)"
  default     = 0
}

variable "node_memory" {
  type        = string
  description = "Memory limit per container e.g. '4GiB' (empty string = LXD default, unlimited)"
  default     = ""
}

variable "ssh_port_base" {
  type        = number
  description = "Base SSH port for containers. Each gets ssh_port_base + index (validator01=base+0, validator02=base+1, ...)."
  default     = 2200
}

variable "http_port_base" {
  type        = number
  description = "Base HTTP API port for AvalancheGo. Each container gets http_port_base + index."
  default     = 9650
}

variable "staking_port_base" {
  type        = number
  description = "Base staking port for AvalancheGo. Each container gets staking_port_base + index. Default leaves a 100-port gap from http_port_base."
  default     = 9751
}
