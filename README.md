# ansible-avalanche-getting-started

How to use the [nuttymoon.avalanche](https://github.com/Nuttymoon/ansible-avalanche-collection) Ansible collection to provision [Avalanche](https://docs.avax.network/) resources.

- [Requirements](#requirements)
- [Installation](#installation)
- [TL;DR](#tldr)
- [Local test network](#local-test-network)
  - [Bootstrapping](#bootstrapping)
  - [API calls](#api-calls)
  - [Pre-funded account](#pre-funded-account)
  - [Customization](#customization)

## Requirements

- Ansible >= 2.9 (see [Installing Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
- For the local test network:
  - 6+ GB of free RAM
  - Vagrant (see [Installing Vagrant](https://www.vagrantup.com/docs/installation))
  - VirtualBox (see [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads))

## Installation

1. Clone this repository:

   ```sh
   git clone https://github.com/Nuttymoon/ansible-avalanche-collection-examples
   ```

2. Install the `nuttymoon.avalanche` collection:

   ```sh
   cd ansible-avalanche-collection-examples

   # With Ansible >= 2.10
   ansible-galaxy collection install git+https://github.com/Nuttymoon/ansible-avalanche-collection.git

   # With Ansible 2.9
   mkdir -p ansible_collections/nuttymoon
   git clone https://github.com/Nuttymoon/ansible-avalanche-collection.git ansible_collections/nuttymoon/avalanche
   ```

## TL;DR

Local test network:

```sh
vagrant up
ansible-playbook nuttymoon.avalanche.bootstrap_local_network -i inventories/local
curl -s -X POST --data '{
  "jsonrpc": "2.0",
  "id"     : 1,
  "method" : "info.isBootstrapped",
  "params": {
    "chain": "P"
  }
}' -H 'content-type:application/json;' http://192.168.2.11:9650/ext/info
```

## Local test network

Create a virtualized local Avalanche test network with 2 commands.

### Bootstrapping

We will use the [nuttymoon.avalanche.bootstrap_local_network](https://github.com/Nuttymoon/ansible-avalanche-collection/blob/main/playbooks/bootstrap_local_network.yml) playbook:

1. Create the 5 virtual machines that will host the Avalanche nodes:

   ```sh
   vagrant up
   ```

2. Bootstrap the Avalanche nodes:

   ```sh
   # With Ansible >= 2.11
   ansible-playbook nuttymoon.avalanche.bootstrap_local_network -i inventories/local

   # With Ansible <= 2.10
   ansible-playbook ansible_collections/nuttymoon/avalanche/playbooks/bootstrap_local_network.yml -i inventories/local
   ```

### API calls

The node `validator01-local` exposes AvalancheGo APIs on it's public IP: you can query any [Avalanche API](https://docs.avax.network/build/avalanchego-apis/) at `192.168.1.11:9650` from your terminal. For example, to check if the P-Chain is done bootstrapping:

```sh
curl -s -X POST --data '{
  "jsonrpc": "2.0",
  "id"     : 1,
  "method" : "info.isBootstrapped",
  "params": {
    "chain": "P"
  }
}' -H 'content-type:application/json;' http://192.168.2.11:9650/ext/info
```

**Note:** The other nodes expose the APIs on there localhost address `127.0.0.1` so you would have to `vagrant ssh` into the VM to query them.

### Pre-funded account

A user with access to the default pre-funded account (see [Fund a Local Test Network](https://docs.avax.network/build/tutorials/platform/fund-a-local-test-network)) is automatically created on `validator01-local`:

- Username: `ewoq`
- Password: `I_l1ve_@_Endor`
- Private key: `PrivateKey-ewoqjP7PxY4yr3iLTpLisriqt94hdyDFNgchSxGGztUrTXtNN`

### Customization

Different aspects of the installation can be customized:

- To customize the VMs specs: edit the [Vagrantfile](./Vagrantfile) and the [`hosts` file](./inventories/local/hosts) accordingly
- To customize AvalancheGo installation: edit the variables in `inventories/local/group_vars`:
  - [avalanche_nodes.yml](./inventories/local/group_vars/avalanche_nodes.yml) is applied to all nodes
  - [bootstrap_node.yml](./inventories/local/group_vars/bootstrap_node.yml) is only applied to the bootstrap node

For a list of all available variables, see the [nuttymoon.avalanche.node role documentation](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/roles/node).
