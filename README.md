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

3. Install the `ash.avalanche` collection and its dependencies:

   ```bash
   ansible-galaxy collection install git+https://github.com/AshAvalanche/ansible-avalanche-collection.git,0.12.1-2
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

2. Spin up the Ethereum node:
   
   ```bash
   ansible-playbook playbooks/local_ethereum.yml -i inventories/local
   ```

3. Bootstrap the Avalanche nodes:

   ```bash
   ansible-playbook ash.avalanche.bootstrap_local_network -i inventories/local
   ```

**Note:** The [`avalanche_nodes.yml`](./inventories/local/group_vars/avalanche_nodes.yml) contains the `avalanchego_vms_list` variable in which we define that the VM binary will be `tokenvm` in version `0.0.666` fetched from the local file `./files/tokenvm_0.0.666_linux_amd64.tar.gz`.

4. Create the Nodekit SEQ Subnet and Blockchain

   ```bash
   ansible-playbook ash.avalanche.create_subnet -i inventories/local
   ```

5. Add the Subnet ID to the `avalanchego_track_subnets` variable in `inventories/local/group_vars/avalanche_nodes.yml`:

   ```yaml
   avalanchego_track_subnets:
      - 29uVeLPJB1eQJkzRemU8g8wZDw5uJRqpab5U2mX9euieVwiEbL
   ```

6. Reprovision the Avalanche nodes to track the new subnet:

   ```bash
   ansible-playbook ash.avalanche.provision_nodes -i inventories/local
   ```

## VM update

To test another release of the `tokenvm` VM, you can update the `avalanchego_vms_list` variable in [`avalanche_nodes.yml`](./inventories/local/group_vars/avalanche_nodes.yml). For example:

```yaml
avalanchego_vms_list:
  tokenvm:
    path: "{{ inventory_dir }}/../../files" # tokenvm_0.0.667_linux_amd64.tar.gz
    id: tHBYNu8ikqo4MWMHehC9iKB9mR5tB3DWzbkYmTfe9buWQ5GZ8
    # Used in Ash CLI
    ash_vm_type: Custom
    binary_filename: tokenvm
    versions_comp:
      0.0.667:
        ge: 1.10.10
        le: 1.10.12
```

Then run the following command:

```bash
ansible-playbook ash.avalanche.provision_nodes -i inventories/local
```

AvalancheGo will automatically restart and the chain will be updated to the new version of Nodekit SEQ.

## Chain import

```bash
/path/to/token-cli chain import
chainID: 2ArqB8j5FWQY9ZBtA3QFJgiH9EmXzbqGup5kuyPQZVZcL913Au
✔ uri: http://10.252.190.111:9650/ext/bc/2ArqB8j5FWQY9ZBtA3QFJgiH9EmXzbqGup5kuyPQZVZcL913Au
```

**Note:** `10.252.190.111` is the IP address of the `validator01` VM, you can get it with `terraform -chdir=terraform/multipass output`.

## Chain watch

```bash
/path/to/token-cli chain watch
database: .token-cli
available chains: 1 excluded: []
1) chainID: 2ArqB8j5FWQY9ZBtA3QFJgiH9EmXzbqGup5kuyPQZVZcL913Au
select chainID: 0 [auto-selected]
uri: http://10.252.190.111:9650/ext/bc/2ArqB8j5FWQY9ZBtA3QFJgiH9EmXzbqGup5kuyPQZVZcL913Au
Here is network Id: %d 12345
Here is uri: %s http://10.252.190.111:9650/ext/bc/2ArqB8j5FWQY9ZBtA3QFJgiH9EmXzbqGup5kuyPQZVZcL913Au
watching for new blocks on 2ArqB8j5FWQY9ZBtA3QFJgiH9EmXzbqGup5kuyPQZVZcL913Au 👀
height:54 l1head:%!s(int64=106) txs:0 root:kMYb8yTR9pbtfFs5hfuEZLDjVjWnepSjpRE3kkXrEeJ2JyPAA blockId:KSLxXyN7XT67n5ubbzHzW7afA6tTjn5hmyqxwr5o4JRSt5wGi size:0.10KB units consumed: [bandwidth=0 compute=0 storage(read)=0 storage(create)=0 storage(modify)=0] unit prices: [bandwidth=100 compute=100 storage(read)=100 storage(create)=100 storage(modify)=100]
height:55 l1head:%!s(int64=107) txs:0 root:23ArBGmR9DQQLab1icAGFZbKd941FdrZuEy5oY2Yj6ZtKDri9M blockId:22zLgkd5bDmgu2qHqDBYQognAktpnp946vHx1MxDGYG38WCZPe size:0.10KB units consumed: [bandwidth=0 compute=0 storage(read)=0 storage(create)=0 storage(modify)=0] unit prices: [bandwidth=100 compute=100 storage(read)=100 storage(create)=100 storage(modify)=100] [TPS:0.00 latency:110ms gap:2474ms]
height:56 l1head:%!s(int64=108) txs:0 root:JZ5w66ZU2MbyaVGqEKoLZ92XHvRnht9Wy79mxNRXJ4k9ZNU3z blockId:K6f61bRPavvJDxuKD4rBmBDLoNTptJWJvJD9zxFcevL3Scjqj size:0.10KB units consumed: [bandwidth=0 compute=0 storage(read)=0 storage(create)=0 storage(modify)=0] unit prices: [bandwidth=100 compute=100 storage(read)=100 storage(create)=100 storage(modify)=100] [TPS:0.00 latency:125ms gap:2533ms]
height:57 l1head:%!s(int64=109) txs:0 root:2EmEPrLQL2a8n8MNPsFExLejWUaZsPsW9tZsnhGJSp4Btmh65q blockId:wNFtM2EnQy1u19sPZzo9cfgfesaSWJPgESzjU6gSU1JZcb328 size:0.10KB units consumed: [bandwidth=0 compute=0 storage(read)=0 storage(create)=0 storage(modify)=0] unit prices: [bandwidth=100 compute=100 storage(read)=100 storage(create)=100 storage(modify)=100] [TPS:0.00 latency:109ms gap:2486ms]
height:58 l1head:%!s(int64=109) txs:0 root:2DdjYeckENJmq92HWsSs8D6DFQpqiCtQFjDMaMWXrjFfQPbwQw blockId:2iJPUrPDSbNjUXQd8tfkQFGyJ7nyxjtorha2TLJdx2UWrrX6HT size:0.10KB units consumed: [bandwidth=0 compute=0 storage(read)=0 storage(create)=0 storage(modify)=0] unit prices: [bandwidth=100 compute=100 storage(read)=100 storage(create)=100 storage(modify)=100] [TPS:0.00 latency:118ms gap:2532ms]
height:59 l1head:%!s(int64=110) txs:0 root:2YmfCHEBQ5GrDqsRydPQcMTacYS1QaCdaVsPw5JkTrof6H6Jjf blockId:NppsG239uko64QQHWpPEDx9GTuQvwVRTN5wvFHmjZPgpRDBhh size:0.10KB units consumed: [bandwidth=0 compute=0 storage(read)=0 storage(create)=0 storage(modify)=0] unit prices: [bandwidth=100 compute=100 storage(read)=100 storage(create)=100 storage(modify)=100] [TPS:0.00 latency:112ms gap:2500ms]
```
