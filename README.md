# ansible-avalanche-getting-started

How to use the [ash.avalanche](https://github.com/AshAvalanche/ansible-avalanche-collection) Ansible collection to provision [Avalanche](https://docs.avax.network/) resources.

- [Requirements](#requirements)
- [Installation](#installation)
- [TL;DR](#tldr)
- [Tutorials](#tutorials)

## Requirements

- Python >=3.9 with `venv` module installed
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
   git clone https://github.com/AshAvalanche/ansible-avalanche-getting-started
   cd ansible-avalanche-collection-getting-started
   ```

2. Setup and activate Python venv:

   ```sh
   bin/setup.sh
   source .venv/bin/activate
   ```

3. Install the `ash.avalanche` collection:

   ```sh
   ansible-galaxy collection install git+https://github.com/AshAvalanche/ansible-avalanche-collection.git
   ```

## TL;DR

Local test network:

```sh
vagrant up
ansible-playbook ash.avalanche.bootstrap_local_network -i inventories/local
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
ansible-playbook ash.avalanche.provision_nodes -i inventories/$NETWORK
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
ansible-playbook ash.avalanche.create_local_subnet -i inventories/local --extra-vars "{\"subnet_control_keys\": [\"$key_1\",\"$key_2\"]}"
```

Blockchain creation (on local test network):

```sh
ansible-playbook ash.avalanche.create_local_blockchains -i inventories/local \
  -e subnet_id=$MY_SUBNET_ID
```

## Tutorials

Check out [docs.ash.center](https://docs.ash.center/docs/category/ansible-avalanche-collection) for complete tutorials to learn how to upgrade AvalancheGo, manage Subnets and more!
