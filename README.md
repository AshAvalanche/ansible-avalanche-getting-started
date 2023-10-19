# ansible-avalanche-getting-started

How to use the [ash.avalanche](https://github.com/AshAvalanche/ansible-avalanche-collection) Ansible collection to provision [Avalanche](https://docs.avax.network/) resources.

## Documentation

The complete documentation related to this project starts by the [Local Test Network Creation tutorial](https://ash.center/docs/toolkit/ansible-avalanche-collection/tutorials/local-test-network).

## Requirements

- Python >=3.9 with `venv` module installed
- For the local test network:
  - 7+GiB of free RAM
  - [Multipass](https://multipass.run) installed (see [Install Multipass](https://multipass.run/install))
  - [Terraform](https://terraform.io) installed (see [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- For filtering outputs:
  - [jq](https://stedolan.github.io/jq/) (see [Download jq](https://stedolan.github.io/jq/download/))

## Setup the environment

1. Clone the Getting Started repository:

   ```bash
   git clone https://github.com/AshAvalanche/ansible-avalanche-getting-started
   cd ansible-avalanche-collection-getting-started
   ```

2. Setup and activate Python venv:

   ```bash
   bin/setup.sh
   source .venv/bin/activate
   ```

3. Install the `ash.avalanche` collection:

   ```bash
   ansible-galaxy collection install git+https://github.com/AshAvalanche/ansible-avalanche-collection.git
   ```

4. Initialize the Terraform modules:

   ```bash
   terraform -chdir=terraform/multipass init
   ```

## Bootstrap the local test network

1. Create the virtual machines that will host the validator nodes using Terraform (enter `yes` when prompted):

   ```bash
   terraform -chdir=terraform/multipass apply
   ```

2. Bootstrap the Avalanche nodes:

   ```bash
   ansible-playbook ash.avalanche.bootstrap_local_network -i inventories/local
   ```

## Docker Compose

It is possible to build Docker images for the Avalanche nodes using [Packer](https://developer.hashicorp.com/packer) and run them using Docker Compose. See [docker/README.md](./docker/README.md) for more information.
