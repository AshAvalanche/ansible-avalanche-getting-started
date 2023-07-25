# Provider: multipass
terraform {
  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "1.4.2"
    }
  }
}

provider "multipass" {}

# Multipass instances
resource "multipass_instance" "validators" {
  for_each = {
    for i in range(1, 6) : "validator0${i}" => i
  }

  name           = each.key
  image          = "jammy"
  cpus           = 1
  memory         = "1GiB"
  disk           = "20GiB"
  cloudinit_file = "../../files/multipass/cloud-init.yaml"
}

data "multipass_instance" "validators_info" {
  depends_on = [
    multipass_instance.validators
  ]

  for_each = {
    for i in range(1, 6) : "validator0${i}" => i
  }

  name = each.key
}

resource "multipass_instance" "frontend" {
  name           = "frontend"
  image          = "jammy"
  cpus           = 2
  memory         = "2GiB"
  disk           = "20GiB"
  cloudinit_file = "../../files/multipass/cloud-init.yaml"
}

data "multipass_instance" "frontend_info" {
  depends_on = [
    multipass_instance.frontend
  ]

  name = "frontend"
}

# Ansible hosts templating
resource "local_file" "ansible_hosts" {
  content = templatefile(
    "hosts.tftpl",
    {
      validators = values(data.multipass_instance.validators_info)
      frontend   = data.multipass_instance.frontend_info
    }
  )
  filename = "hosts.ini"
}

# Ash CLI configuration templating
resource "local_file" "ash_cli_config" {
  content = templatefile(
    "local-test-network.tftpl",
    {
      validators = values(data.multipass_instance.validators_info)
    }
  )
  filename = "local-test-network.yml"
}

# Outputs
output "validators_ips" {
  value = values(data.multipass_instance.validators_info).*.ipv4
}

output "frontend_ip" {
  value = data.multipass_instance.frontend_info.ipv4
}
