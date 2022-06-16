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
  - [VMs installation and upgrade](#vms-installation-and-upgrade)
- [Avalanche transactions](#avalanche-transactions)
  - [Example notebook](#example-notebook)
- [Subnet management](#subnet-management)
  - [Prerequisites](#prerequisites)
  - [Subnet creation](#subnet-creation)
  - [Subnet whitelisting](#subnet-whitelisting-1)
  - [Customization](#customization-2)
- [Blockchains management](#blockchains-management)
  - [Prerequisites](#prerequisites-1)
  - [Blockchain creation](#blockchain-creation)
  - [Customization](#customization-3)

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
   git clone https://github.com/Nuttymoon/ansible-avalanche-getting-started
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
  "jsonrpc": "2.0", "id": 1,
  "method" : "info.isBootstrapped",
  "params": { "chain": "P" }
}' -H 'content-type:application/json;' http://192.168.60.11:9650/ext/info
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

Subnet creation (on local test network). Using `jq` to parse API output:

```sh
# Prerequisite: create 2 addresses on P-Chain for pre-funded account
data='{
  "jsonrpc": "2.0", "id": 1, "method" : "platform.createAddress",
  "params" : {"username":"ewoq", "password": "I_l1ve_@_Endor"}
}'
key_1=$(curl -s -X POST -H 'content-type:application/json;' --data "$data" http://192.168.60.11:9650/ext/bc/P | jq -r '.result.address')
key_2=$(curl -s -X POST -H 'content-type:application/json;' --data "$data" http://192.168.60.11:9650/ext/bc/P | jq -r '.result.address')
ansible-playbook nuttymoon.avalanche.create_local_subnet -i inventories/local --extra-vars "{\"subnet_control_keys\": [\"$key_1\",\"$key_2\"]}"
```

Blockchain creation (on local test network):

```sh
ansible-playbook nuttymoon.avalanche.create_local_blockchains -i inventories/local \
  -e subnet_id=$MY_SUBNET_ID
```

## Local test network

Use `nuttymoon.avalanche.node` to create a virtualized local Avalanche test network.

### Bootstrapping

We will use the [nuttymoon.avalanche.bootstrap_local_network](https://github.com/Nuttymoon/ansible-avalanche-collection/blob/main/playbooks/bootstrap_local_network.yml) playbook (that relies on the `node` role):

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

The node `validator01-local` exposes AvalancheGo APIs on it's public IP: you can query any [Avalanche API](https://docs.avax.network/build/avalanchego-apis/) at `192.168.60.11:9650` from your terminal. For example, to check if the P-Chain is done bootstrapping:

```sh
curl -s -X POST --data '{
  "jsonrpc": "2.0",
  "id"     : 1,
  "method" : "info.isBootstrapped",
  "params": {
    "chain": "P"
  }
}' -H 'content-type:application/json;' http://192.168.60.11:9650/ext/info
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

Use `nuttymoon.avalanche.node` to provision Avalanche nodes.

### Provisioning

We will use the [nuttymoon.avalanche.provision_nodes](https://github.com/Nuttymoon/ansible-avalanche-collection/blob/main/playbooks/provision_nodes.yml) playbook (that relies on the `node` role):

1. Create the `hosts` file in the inventory with your host information (e.g. for `fuji`):

   ```sh
   cat << EOF > inventories/fuji/hosts
   validator01 ansible_host=${MY_HOST_IP} ansible_user=${MY_HOST_USER}
   [avalanche_nodes]
   validator01
   EOF
   ```

2. Provision the Avalanche nodes (e.g. for `fuji`):

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

### VMs installation and upgrade

To install or upgrade VMs on the nodes, update the variable `avalanchego_vms_install`:

```yaml
avalanchego_vms_install:
  - timestampvm=1.2.2
  - spacesvm=0.0.2
```

For the list of all VMs available see the [nuttymoon.avalanche.node role documentation](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/roles/node/#available-vms-and-avalanchego-compatibility).

## Avalanche transactions

Use the `nuttymoon.avalanche.tx` module to submit transactions to an Avalanche network.

### Example notebook

The notebook [nuttymoon.avalanche.transfer_avax](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/playbooks/transfer_avax.yml) is provided as an example. We will call this notebook and follow best practices to secure Avalanche keystore credentials using [Ansible vault](https://docs.ansible.com/ansible/latest/user_guide/vault.html):

1. In [inventories/local/group_vars/api_node.yml](inventories/local/group_vars/api_node.yml), the keystore crendentials have been encrypted using Ansible vault:
   ```yaml
   avax_transfer_from_username: !vault |
     $ANSIBLE_VAULT;1.1;AES256
     65643665373461343366366161623038383134396339303931386131653662356663366530613539
     3461323730646262626531396461353164653939333730380a393637626637366136366439383035
     37653661343365376531316264316464343763356136306430383865363863343933323333373437
     6366336430313233340a343465316663653630626566363131636438333338383236613631633563
     6138
   avax_transfer_from_password: !vault |
     $ANSIBLE_VAULT;1.1;AES256
     36363962333839616366363730306264373332373336316332356162323230313039393265626639
     6265613633623538396266323232353130643466646261370a653161333066663034346536346365
     38346235653736636438663265353130303665323939343663663961386635626539616464373636
     3232643435333437660a666137323964386338316361333931356232616163663636646262386130
     3461
   ```
   This avoids storing usernames and passwords in plain text.
2. To run the notebook, we need to provide the vault password (`ewoq`):

   ```sh
   # With Ansible >= 2.11
   ansible-playbook nuttymoon.avalanche.transfer_avax -i inventories/local --ask-vault-password

   # With Ansible <= 2.10
   ansible-playbook ansible_collections/nuttymoon/avalanche/playbooks/transfer_avax.yml -i inventories/local --ask-vault-password
   ```

3. The notebook issues 2 transactions to transfer 1 AVAX from the X-Chain to the C-Chain and you can see the `tx` module output format:
   ```yaml
   xchain_transac_res:
     blockchain: X
     changed: true
     endpoint: http://192.168.60.11:9650/ext/bc/X
     failed: false
     num_retries: 0
     response:
       id: 1
       jsonrpc: "2.0"
       result:
         status: Accepted
     tx_data:
       id: 1
       jsonrpc: "2.0"
       method: avm.export
       params:
         amount: 1000000000
         assetID: AVAX
         password: VALUE_SPECIFIED_IN_NO_LOG_PARAMETER
         to: C-local18jma8ppw3nhx5r4ap8clazz0dps7rv5u00z96u
         username: VALUE_SPECIFIED_IN_NO_LOG_PARAMETER
     tx_id: 2vQi7Smp7jm39moowZNZMfCfismswerYVtB14iSHk4jfg6nPyA
   ```

## Subnet management

Use `nuttymoon.avalanche.subnet` to create a subnet.

### Prerequisites

For this example, we will use our local test network and the [nuttymoon.avalanche.create_local_subnet](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/playbooks/create_local_subnet.yml) notebook that uses the pre-funded account to create the subnet. Therefore, before creating the subnet, we need to:

1. (If not already done) Create the local test network, see [Local test network](#local-test-network)
2. Create 2 addresses that will serve as control keys for the subnet (see [Create a subnet](https://docs.avax.network/build/tutorials/platform/subnets/create-a-subnet) for more information):

   ```sh
   data='{
     "jsonrpc": "2.0", "id": 1, "method" : "platform.createAddress",
     "params" : {"username":"ewoq", "password": "I_l1ve_@_Endor"}
   }'
   key_1=$(curl -s -X POST -H 'content-type:application/json;' --data "$data" http://192.168.60.11:9650/ext/bc/P | jq -r '.result.address')
   key_2=$(curl -s -X POST -H 'content-type:application/json;' --data "$data" http://192.168.60.11:9650/ext/bc/P | jq -r '.result.address')
   ```

### Subnet creation

We will use the 2 addresses created above as control keys for the subnet:

```sh
# With Ansible >= 2.11
ansible-playbook nuttymoon.avalanche.create_local_subnet -i inventories/local \
  --extra-vars "{\"subnet_control_keys\": [\"$key_1\",\"$key_2\"]}"

# With Ansible >= 2.10
ansible-playbook ansible_collections/nuttymoon/avalanche/playbooks/create_local_subnet.yml \
  -i inventories/local --extra-vars "{\"subnet_control_keys\": [\"$key_1\",\"$key_2\"]}"
```

### Subnet whitelisting

The `nuttymoon.avalanche.subnet` role does not whitelist the subnet on validators. The list of whitelisted subnets is handled by the `nuttymoon.avalanche.node` role.

At the end of the subnet creation, information about the new subnet is displayed:

```yaml
ok: [validator01] =>
  msg: |-
    The subnet has been created and the validators added.
    Make sure to add the subnet ID to the whitelisted-subnets list of the validators.
    Subnet ID = 2mt2C4vRbkrmAAurm7FE3y4xzan4CM3jJSKaPeCCuVq8EaphMR
```

To whitelist the subnet:

1. Edit the `group_vars` file associated with the hosts to add the `avalanche_whitelisted_subnet` variable. In our case it is [avalanche_nodes.yml](./inventories/local/group_vars/avalanche_nodes.yml):
   ```yaml
   avalanche_whitelisted_subnets: 2mt2C4vRbkrmAAurm7FE3y4xzan4CM3jJSKaPeCCuVq8EaphMR
   ```
2. Run the `nuttymoon.avalanche.bootstrap_local_network` to apply the new configuration and restart the nodes

### Customization

To customize the subnet: edit the variables in `inventories/local/group_vars/subnet_control_node.yml`.

For a list of all available variables, see the [nuttymoon.avalanche.subnet role documentation](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/roles/subnet).

## Blockchains management

Use `nuttymoon.avalanche.blockchain` to create a blockchains.

### Prerequisites

For this example, we will use our local test network and the [nuttymoon.avalanche.create_local_blockchains](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/playbooks/create_local_blockchains.yml) notebook that uses the pre-funded account to create blockchains in an existing subnet. Therefore, before creating the blockchain, we need to:

1. (If not already done) Create the local test network, see [Local test network](#local-test-network)
2. (If not already done) Create a subnet, see [Subnet management](#subnet-management). Note down the subnet ID.
3. (If not already done) Restart the nodes with the subnet ID whitelisted. See [Subnet whitelisting](#subnet-whitelisting-1). Note down the subnet ID.

### Blockchain creation

The playboook [nuttymoon.avalanche.create_local_blockchains](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/playbooks/create_local_blockchains.yml) will create the blockchains listed in the `create_blockchains` variable in `inventories/local/group_vars/subnet_control_node.yml`. By default, 2 blockchains are created:

- `Timestamp Chain` using the `timestampvm` VM
- `Subnet EVM` using the `subnetevm` VM

```sh
# With Ansible >= 2.11
ansible-playbook nuttymoon.avalanche.create_local_blockchains -i inventories/local \
  -e subnet_id=$MY_SUBNET_ID

# With Ansible >= 2.10
ansible-playbook ansible_collections/nuttymoon/avalanche/playbooks/create_local_blockchains.yml \
  -i inventories/local -e subnet_id=$MY_SUBNET_ID
```

The blockchain information are displayed at the end of its creation:

```yaml
ok: [validator01] =>
  blockchain_info:
    id: 2qySivgXbE13Guu3icudmMj5HTnDiXnJHznLd22JZSWCCA3tbL
    name: Subnet EVM
    subnetID: 21ieRfp2vi7kCQ9QHxhyRxyR7FXVy9s9pUAewoV8E4DxYSydZp
    vmID: spePNvBxaWSYL2tB5e2xMmMNBQkXMN8z2XEbz1ML2Aahatwoc
```

### Customization

To customize the blockchains created: edit the variables in `inventories/local/group_vars/subnet_control_node.yml`.

For a list of all available variables, see the [nuttymoon.avalanche.blockchain role documentation](https://github.com/Nuttymoon/ansible-avalanche-collection/tree/main/roles/blockchain).
