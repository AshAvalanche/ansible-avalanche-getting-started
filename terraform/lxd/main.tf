terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

locals {
  nodes = {
    for i in range(var.nodes_count) :
    format("validator%02d", i + 1) => {
      index        = i
      ssh_port     = var.ssh_port_base + i
      http_port    = var.http_port_base + i
      staking_port = var.staking_port_base + i
    }
  }
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_file)))
  cloud_init = templatefile("${path.module}/cloud-init.tftpl", {
    ssh_public_key = local.ssh_public_key
  })
}

# Install and initialize LXD on the host once before creating any containers.
# This runs only when host/user change (i.e., almost never after first apply).
resource "null_resource" "lxd_setup" {
  triggers = {
    host          = var.lxd_host_address
    user          = var.lxd_ssh_user
    # Increment to force re-run when setup logic changes.
    setup_version = "2"
  }

  connection {
    type  = "ssh"
    host  = self.triggers.host
    user  = self.triggers.user
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      # Install LXD snap if not present
      "snap list lxd > /dev/null 2>&1 || sudo snap install lxd --channel=latest/stable",
      "sleep 3",
      # Create default storage pool (dir backend) if none exists.
      # --format csv has no header row, so grep only matches on actual data.
      "sudo /snap/bin/lxc storage list --format csv 2>/dev/null | grep -q '^default,' || sudo /snap/bin/lxc storage create default dir",
      # Add root disk device to default profile if missing.
      "sudo /snap/bin/lxc profile show default 2>/dev/null | grep -q 'path: /' || sudo /snap/bin/lxc profile device add default root disk path=/ pool=default",
      # Create lxdbr0 bridge network if missing.
      "sudo /snap/bin/lxc network list --format csv 2>/dev/null | grep -q '^lxdbr0,' || sudo /snap/bin/lxc network create lxdbr0",
      # Add eth0 NIC to default profile if missing.
      "sudo /snap/bin/lxc profile show default 2>/dev/null | grep -q 'parent: lxdbr0' || sudo /snap/bin/lxc profile device add default eth0 nic nictype=bridged parent=lxdbr0 name=eth0",
    ]
  }
}

resource "null_resource" "node" {
  for_each   = local.nodes
  depends_on = [null_resource.lxd_setup]

  # host and user are stored in triggers so the destroy provisioner can
  # reference them via self.triggers (destroy provisioners cannot use vars).
  triggers = {
    name         = each.key
    ssh_port     = tostring(each.value.ssh_port)
    http_port    = tostring(each.value.http_port)
    staking_port = tostring(each.value.staking_port)
    cloud_init   = sha256(local.cloud_init)
    host         = var.lxd_host_address
    user         = var.lxd_ssh_user
  }

  connection {
    type  = "ssh"
    host  = self.triggers.host
    user  = self.triggers.user
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      # Delete existing container if present (handles recreation on config change)
      "sudo /snap/bin/lxc info ${each.key} > /dev/null 2>&1 && sudo /snap/bin/lxc delete --force ${each.key} || true",
      # Initialize container in stopped state
      "sudo /snap/bin/lxc init ubuntu:22.04 ${each.key}",
      # Set cloud-init user-data (base64 avoids shell quoting issues with YAML)
      "echo '${base64encode(local.cloud_init)}' | base64 -d | sudo /snap/bin/lxc config set ${each.key} user.user-data -",
      # Apply resource limits only when explicitly set (0 / empty = LXD default, unlimited)
      "[ ${var.node_cpu} -eq 0 ] || sudo /snap/bin/lxc config set ${each.key} limits.cpu ${var.node_cpu}",
      "[ -z '${var.node_memory}' ] || sudo /snap/bin/lxc config set ${each.key} limits.memory '${var.node_memory}'",
      # Add LXD proxy devices: expose the same port on host and container (no NAT)
      "sudo /snap/bin/lxc config device add ${each.key} proxy_ssh proxy listen=tcp:0.0.0.0:${each.value.ssh_port} connect=tcp:127.0.0.1:22",
      "sudo /snap/bin/lxc config device add ${each.key} proxy_http proxy listen=tcp:0.0.0.0:${each.value.http_port} connect=tcp:127.0.0.1:${each.value.http_port}",
      "sudo /snap/bin/lxc config device add ${each.key} proxy_staking proxy listen=tcp:0.0.0.0:${each.value.staking_port} connect=tcp:127.0.0.1:${each.value.staking_port}",
      # Start container and wait for cloud-init (ensures SSH + Python3 ready for Ansible)
      "sudo /snap/bin/lxc start ${each.key}",
      "sudo /snap/bin/lxc exec ${each.key} -- cloud-init status --wait > /dev/null",
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "sudo /snap/bin/lxc delete --force ${self.triggers.name} 2>/dev/null || true",
    ]
  }
}

resource "local_file" "ansible_hosts" {
  depends_on = [null_resource.node]
  content = templatefile(
    "${path.module}/hosts.tftpl",
    {
      nodes            = local.nodes
      lxd_host_address = var.lxd_host_address
      lxd_ssh_user     = var.lxd_ssh_user
    }
  )
  filename = "${path.module}/hosts.ini"
}
