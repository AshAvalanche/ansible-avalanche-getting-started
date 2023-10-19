# Local Avalanche Test Network with Docker

For some use cases, it can be useful to pre-build Docker images and run the local Avalanche test network using Docker Compose.

## Requirements

- [Docker](https://docs.docker.com) installed (see [Get Docker](https://docs.docker.com/get-docker/))
- [Packer](https://developer.hashicorp.com/packer) installed (see [Install Packer](https://developer.hashicorp.com/packer/downloads))
- [Ansible](https://docs.ansible.com/ansible) installed (see [Installing Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
- The `ash.avalanche` collection installed (see [Setup the environment](../README.md#setup-the-environment))
- The Avalanche VM to install has to be specified by enriching the `avalanchego_vms_list` variable in [../inventories/local/avalanche_nodes.yml](../inventories/local/avalanche_nodes.yml). Example:

  ```yaml
  avalanchego_vms_list:
    ash-subnet-evm:
      download_url: https://github.com/AshAvalanche/subnet-evm/releases/download
      id: jvFWMths2qLjsZgbyEKx82PkQv2YWR4rotjQfxV55vLLogjNA
      # Used in Ash CLI
      ash_vm_type: Custom
      aliases:
        - ash-subnet-evm
      versions_comp:
        0.666.0:
          ge: 1.10.5
          le: 1.10.8
  ```

## Build the Docker images

The `avalanche-node-*.pkr.hcl` Packer templates allow to build Docker images for the 5 Avalanche nodes of the `local` network with:

- 1 fixed version of AvalancheGo
- 1 fixed version of an Avalanche VM

Out of simplicity, the `build.sh` script is provided:

```bash
cd docker

# Set the AvalancheGo version
export AVALANCHEGO_VERSION=1.10.9
# Set the Avalanche VM to install with its version
export AVALANCHEGO_VM_NAME=subnet-evm
export AVALANCHEGO_VM_VERSION=0.5.6

./build.sh
```

The build will publish the following Docker images to the local Docker registry:

```bash
$ docker image ls
REPOSITORY                            TAG                      IMAGE ID      CREATED            SIZE
ash/avalanche-node-local-validator05  1.10.9-subnet-evm-0.5.6  810187bfeb08  About an hour ago  368MB
ash/avalanche-node-local-validator04  1.10.9-subnet-evm-0.5.6  fe05a65bb297  About an hour ago  368MB
ash/avalanche-node-local-validator03  1.10.9-subnet-evm-0.5.6  52f16e544a21  About an hour ago  368MB
ash/avalanche-node-local-validator02  1.10.9-subnet-evm-0.5.6  ac9e3f3b88af  About an hour ago  368MB
ash/avalanche-node-local-validator01  1.10.9-subnet-evm-0.5.6  8c101af0e369  About an hour ago  368MB
ash/avalanche-node                    1.10.9-subnet-evm-0.5.6  4fe58ef61de4  About an hour ago  368MB
```

## Start the local Avalanche test network with Docker Compose

To start the local Avalanche test network with Docker Compose, simply run `docker compose up -d`.

## Creating a local Subnet

To create a local Subnet, you can use the same playbook as for the Multipass-based local test network:

```bash
# Note: you may have to wait a few seconds for the network to be bootstrapped and ready

ansible-playbook ash.avalanche.create_subnet -i inventories/local
```

To track the newly created Subnet, restart the Docker containers after adding the Subnet ID to the `track-subnets` configuration parameter of the Avalanche nodes:

```bash
for v in {1..5}; do
  sed -i 's/"track-subnets": ".*"/"track-subnets": "29uVeLPJB1eQJkzRemU8g8wZDw5uJRqpab5U2mX9euieVwiEbL"/' "data/conf/validator0$v/conf/node.json";
done

docker compose restart
```

## Using the Ash CLI

```bash
docker exec -t ash-avalanche-local-validator01 ash avalanche subnet list
```
