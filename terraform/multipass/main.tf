# Provider: multipass
terraform {
  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "1.4.2"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
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

# Outputs
output "validators_ips" {
  value = values(data.multipass_instance.validators_info).*.ipv4
}

output "frontend_ip" {
  value = data.multipass_instance.frontend_info.ipv4
}

# Docker
provider "docker" {}

# NGINX configuration templating
resource "local_file" "nginx_conf" {
  content  = templatefile(
    "nginx.tftpl",
    {
      validators = values(data.multipass_instance.validators_info)
    }
  )
  filename = abspath("nginx.conf")
}

# NGINX Docker image
resource "docker_image" "nginx" {
  name         = "nginx:1.25.3"
  keep_locally = true
}

# NGINX Docker container
resource "docker_container" "nginx" {
  image = docker_image.nginx.image_id
  name  = "avax_nginx"
  ports {
    internal = 80
    external = 80
  }
  mounts {
    target = "/etc/nginx/nginx.conf"
    type   = "bind"
    source = local_file.nginx_conf.filename
  }
}
