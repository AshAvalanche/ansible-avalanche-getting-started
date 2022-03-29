# Copyright (C) 2022, Gauthier Leonard
# See the file LICENSE for licensing terms.

# -*- mode: ruby -*-
# vi: set ft=ruby :

machines = {
  validator01: { ip: "192.168.10.11", memory: 1024, cpus: 1 },
  validator02: { ip: "192.168.10.12", memory: 1024, cpus: 1 },
  validator03: { ip: "192.168.10.13", memory: 1024, cpus: 1 },
  validator04: { ip: "192.168.10.14", memory: 1024, cpus: 1 },
  validator05: { ip: "192.168.10.15", memory: 1024, cpus: 1 },
}

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  # Define VMs
  machines.each_with_index do |(name, props), i|
    config.vm.define "#{name}-local".to_sym do |node|
      node.vm.network :private_network, ip: props[:ip]
      node.vm.hostname = "#{name}.local" 
      node.vm.provider "virtualbox" do |n|
        n.name =  "#{name}.local"
        n.memory = props[:memory]
        n.cpus = props[:cpus]
        n.customize ["modifyvm", :id, "--ioapic", "on"]
        n.gui = false
      end
    end
  end
end
