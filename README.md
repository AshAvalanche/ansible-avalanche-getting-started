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
- [Fuji/Mainnet nodes](#fujimainnet-nodes)
  - [Provisioning](#provisioning)
  - [API calls](#api-calls-1)
  - [Customization](#customization-1)
  - [Node upgrade](#node-upgrade)
  - [Subnet whitelisting](#subnet-whitelisting)

## Requirements

- Ansible >= 2.9 (see [Installing Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
- For the local test network:
  - 6+ GB of free RAM
  - Vagrant (see [Installing Vagrant](https://www.vagrantup.com/docs/installation))
  - VirtualBox (see [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads))
- For Fuji/Mainnet:
  - Remote servers that fit [Avalanche requirements](https://docs.avax.network/build/tutorials/nodes-and-staking/run-avalanche-node#requirements) (for Fuji, 200 GB of storage are enough)
  - SSH access to this servers (Ansible will use your key from `~/.ssh` by default)

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
  "params": { "chain": "P" }
}' -H 'content-type:application/json;' http://192.168.2.11:9650/ext/info
```

Fuji/Mainnet nodes (replace `${MY_HOST_IP}` and `${MY_HOST_USER}`):

```sh
NETWORK=fuji # or mainnet
cat << EOF > inventories/$NETWORK/hosts
validator01 ansible_host=${MY_HOST_IP} ansible_user=${MY_HOST_USER}
[avalanche_nodes]
validator01
EOF
ansible-playbook nuttymoon.avalanche.provision_nodes -i inventories/$NETWORK
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

## Fuji/Mainnet nodes

Provision Avalanche nodes with 1 command.

### Provisioning

We will use the [nuttymoon.avalanche.provision_nodes](https://github.com/Nuttymoon/ansible-avalanche-collection/blob/main/playbooks/provision_nodes.yml) playbook:

1. Create the `hosts` file in the inventory with your host information (e.g. for `fuji`):

   ```sh
   cat << EOF > inventories/fuji/hosts
   validator01 ansible_host=${MY_HOST_IP} ansible_user=${MY_HOST_USER}
   [avalanche_nodes]
   validator01
   EOF
   ```

2. Provisio the Avalanche nodes (e.g. for `fuji`):

   ```sh
   # With Ansible >= 2.11
   ansible-playbook nuttymoon.avalanche.provision_nodes -i inventories/fuji

   # With Ansible <= 2.10
   ansible-playbook ansible_collections/nuttymoon/avalanche/playbooks/provision_nodes.yml -i inventories/fuji
   ```

### API calls

For security reasons, the nodes do not expose AvalancheGo APIs on their public IP but on their localhost IP (`http_host=127.0.0.1`). To query the APIs, you have to SSH into your node.

### Customization

To customize AvalancheGo installation: edit the variables in `inventories/NETWORK/group_vars/avalanche_nodes.yml`.

For a list of all available variables, see the [nuttymoon.avalanche.node role documentation](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/roles/node).

### Node upgrade

To upgrade your node to a newer version of AvalancheGo, you just have to:

1. Update the `avalanchego_version` variable in `group_vars/avalanche_nodes.yml`
2. Run the `nuttymoon.avalanche.provision_nodes` playbook: AvalancheGo will be restarted after the new version installation.

**Note:** Because Ansible deployments are idempotent, the node is only restarted when needed. It doesn't hurt to run the playbook to make sure that your node is up to date with your configuration!

### Subnet whitelisting

To whitelist a subnet on your node (so that it can start validating blocks):

1. Add it to `avalanche_whitelisted_subnets` (comma-separated) in `group_vars/avalanche_nodes.yml`
2. Run the `nuttymoon.avalanche.provision_nodes` playbook: AvalancheGo will be restarted after the configuration update.
